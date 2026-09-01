# vim: expandtab:shiftwidth=4:textwidth=80

#
#
# ~/.config/zsh/rc/util/zoxide.rc.zsh
#
#

#
# Fuzzy frecency directory jumper
# https://github.com/ajeetdsouza/zoxide
# https://github.com/ajeetdsouza/zoxide#configuration
#

[[ -o interactive     ]] || return
(( $+commands[zoxide] )) || return

local __this_file="$0"

function __init_zoxide () {
    local _zo_exclude_dirs=(
        "$HOME"
    )
    export _ZO_EXCLUDE_DIRS=${(j|:|)_zo_exclude_dirs}

    local _zo_fzf_opts=(
        "$FZF_DEFAULT_OPTS"
        --preview-window=right,wrap
        --reverse
        --border
        --height 40%
        --scheme=history
    
        "--preview='eza --oneline --color=always --all --group-directories-first --tree --level 1 {2}'"
        --with-nth 2
    )
    export _ZO_FZF_OPTS=${(j: :)_zo_fzf_opts}

    local __init_cache="$zsh_dirs[cache_init]/zoxide.init.zsh"

    # Regenerate init cache if:
    #  - Missing
    #  - Older than binary
    #  - Older than this file
    if  [[ ! -f "$__init_cache" ]] ||\
        [[ "$__init_cache" -ot "$commands[zoxide]" ]] ||\
        [[ "$__init_cache" -ot "$__this_file" ]]
    then
        echo "Regenerating zoxide source cache"
        zoxide init zsh --cmd cd --hook pwd >| "$__init_cache"
    fi

    source "$__init_cache"
}; __init_zoxide; unset -f __init_zoxide

unset __this_file
