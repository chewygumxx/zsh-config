#!/bin/false
# vim: expandtab:shiftwidth=4

#
#
# ~/.config/zsh/rc/completion.rc.zsh
#
#

#
# https://thevaluable.dev/zsh-completion-guide-examples/ 
#

[[ -o interactive ]] || return

# Variables zsh_dirs and ls_colors declared elsewhere

# ---------------
# Populate fpath
# ---------------

function __download_plugin() {
    local slug="$1"
    local plugin="${slug##*/}"

    if [[ ! -d "$zsh_dirs[plugin]/$plugin" ]]; then
        git clone "https://github.com/$slug.git" "$zsh_dirs[plugin]/$plugin"
    fi
}

__download_plugin "zsh-users/zsh-completions"
fpath+=(
    "$zsh_dirs[share_comp]"
    "$zsh_dirs[user_comp]"
    "$zsh_dirs[plugin]/zsh-completions/src"
)

# --------------
# Call compinit
# --------------

# Provides 'menuselect' keymap. Must be loaded before compinit call
zmodload zsh/complist 
_comp_options+=(globdots)

autoload -Uz compinit
setopt list_types extended_glob
# Glob explanation:
#   N      Return an empty list if nothing found, instead of an error
#   mh-24  Return files less than 24 hours old.
if [[ -n "$zsh_dirs[cache]"(Nmh-24) ]]; then
    compinit -C -d  "${zsh_dirs[cache]}/zcompdump"
else
    compinit -d     "${zsh_dirs[cache]}/zcompdump"
fi

# ---------------
# Post compinit
# ---------------

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$zsh_dirs[cache_zstylecomp]"

zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*:*:-command-:*:*' group-order aliases functions builtins commands
zstyle ":completion:*" list-colors $ls_colors

if (( $+commands[fzf] )); then
    # Must be after `compinit` and before widget wrapping plugins
    # `fast-syntax-highlighting` and `zsh-autosuggestions`.
    # https://github.com/aloxaf/fzf-tab

    # Do not source anything that overwrites <Tab> bindkey.
    # (Don't source junegunn/fzf/completion.zsh, only jungunn/fzf/key-bindings.zsh)

    __download_plugin "aloxaf/fzf-tab"
    source "$zsh_dirs[plugin]/fzf-tab/fzf-tab.plugin.zsh"

    # Escape sequences, like '%F{blue}%d%f', will be ignored by fzf-tab
    zstyle ':completion:*:descriptions' format '[%d]'
    # To allow fzf-tab to capture the unambiguous prefix: Force zsh not to show completion menu
    zstyle ':completion:*' menu no
    # Preview directory's content with eza when completing cd
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --oneline --color=always --group-directories-first --long --git --no-permissions --no-filesize --no-user --no-time --ignore-glob="[0-9a-f][0-9a=f]|.obsidian|.zettel-notes" $realpath'

    # Custom fzf flags
    # By default, fzf-tab does not follow FZF_DEFAULT_OPTS
    zstyle ':fzf-tab:*' use-fzf-default-opts yes
    #zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
    # Switch group using `<` and `>`
    zstyle ':fzf-tab:*' switch-group '<' '>'
else 
    zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}[%d]%f'
    zstyle ':completion:*' menu select

    # Dependant on `zmodload zsh/complist` before compinit
    [[ ! -v bindkey_calls ]] && typeset -ga bindkey_calls
    bindkey_calls+=(
        "-M menuselect '^h' vi-backward-char"
        "-M menuselect '^k' vi-up-line-or-history"
        "-M menuselect '^j' vi-down-line-or-history"
        "-M menuselect '^l' vi-forward-char"
    )
fi

unset -f __download_plugin
