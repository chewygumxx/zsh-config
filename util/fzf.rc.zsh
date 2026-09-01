#!/bin/false
# vim: expandtab:shiftwidth=4

#
#
# ~/.config/zsh/rc/util/fzf.rc.zsh
#
#

#
# The ubiquitous command-line fuzzy finder
# https://github.com/junegunn/fzf
# https://github.com/junegunn/fzf#environment-variables
#

[[ -o interactive  ]] || return
(( $+commands[fzf] )) || return

typeset -g __fzf_rc_file="$(\builtin print -D ${${(%):-%N}:A})"

function __fzf_shell_integration () {
    local ctx="${__fzf_rc_file}: (${(%):-%N})"
    unset __fzf_rc_file
    unset -f "${(%):-%N}"

    local data_dir
    if   [[ -d "/usr/share/fzf"    ]]; then  # Arch Linux
        data_dir="/usr/share/fzf"
    elif [[ -d "$PREFIX/share/fzf" ]]; then  # Termux
        data_dir="$PREFIX/share/fzf"
    else
        print -u2 "$ctx fzf data directory not found at '/usr/share/fzf' or '\$PREFIX/share/fzf'"
        return 1
    fi

    # ---------
    # Keybinds
    # ---------
    # CTRL-R
    #     Fuzzy-find command history
    # CTRL-T
    #     Fuzzy-find files recursively from CWD
    # ALT-C
    #     Fuzzy-find directories recursively from CWD and cd
    # https://github.com/junegunn/fzf#key-bindings-for-command-line

    if [[ ! -r "$data_dir/key-bindings.zsh" ]]; then
        print -u2 "$ctx Not found: $data_dir/key-bindings.zsh"
        return 1
    fi

    local interactive_opts=(
        "--reverse"
        "--border"
        "--height 40%"
    )
    local command_fd=(
        "fd"
        "--hidden"
        "--strip-cwd-prefix=always"
        "--one-file-system"
    )

    #export FZF_CTRL_R_COMMAND="echo 'Custom commands not yet supported'"
    local ctrl_r_opts=(
        $interactive_opts
        "--scheme=history"
        "--with-nth 2.."
    )
    export FZF_CTRL_R_OPTS=${(j: :)ctrl_r_opts}

    local ctrl_t_command=(
        $command_fd
    )
    export FZF_CTRL_T_COMMAND=${(j: :)ctrl_t_command}
    local ctrl_t_opts=(
        $interactive_opts
        "--scheme=path"
    )
    export FZF_CTRL_T_OPTS=${(j: :)ctrl_t_opts}

    local alt_c_command=(
        $command_fd
        "--type directory"
    )
    export FZF_ALT_C_COMMAND=${(j: :)alt_c_command}
    local alt_c_opts=(
        $interactive_opts
        "--scheme=path"
    )
    export FZF_ALT_C_OPTS=${(j: :)alt_c_opts}

    source "$data_dir/key-bindings.zsh"

    # -----------
    # Completion
    # -----------
    # https://github.com/junegunn/fzf#fuzzy-completion

    # Plugin 'fzf-tab' loaded:
    # Do not source fzf/completion.zsh. Do not overwrite keybind '^I' (Tab).
    (( $+widgets[fzf-tab-complete] )) && return

    if [[ ! -r "$data_dir/completion.zsh" ]]; then
        print -u2 "$ctx Not found: $data_dir/completion.zsh"
        return 1
    fi

    export FZF_COMPLETION_TRIGGER='**'

    local completion_opts=(
        $interactive_opts
        "--scheme=path"
    )
    export FZF_COMPLETION_OPTS=${(j: :)completion_opts}

    export FZF_COMPLETION_DIR_OPTS='--walker dir,follow'
    export FZF_COMPLETION_PATH_OPTS='--walker file,dir,follow,hidden'

    # TODO(@chewygumxx): (Priority: Low)
    #function _fzf_comprun() {
    #    local command=$1; shift
    #    
    #    case "$command" in
    #        cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    #        export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    #        ssh)          fzf --preview 'dig {}'                   "$@" ;;
    #        *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
    #    esac
    #}

    source "$data_dir/completion.zsh"
}

# -----------
# Initialise
# -----------

# Ensure fzf keybinds are not overridden by plugin 'zsh-vi-mode'
if [[ -n "${ZVM_VERSION-}" ]]; then
    zvm_after_init_commands+=(__fzf_shell_integration)
else
    __fzf_shell_integration
fi
