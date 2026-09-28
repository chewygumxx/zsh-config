#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/zoxide.rc.zsh
#
#
# Fuzzy frecency directory jumper
# https://github.com/ajeetdsouza/zoxide
# https://github.com/ajeetdsouza/zoxide#configuration
#

[[ -o interactive ]] || return
(($+commands[zoxide])) || return

local __this_file="$0"

function __init_zoxide() {
    local _zo_exclude_dirs=(
        "$HOME"
    )
    export _ZO_EXCLUDE_DIRS=${(j|:|)_zo_exclude_dirs}

    local _zo_fzf_opts=(
        "$FZF_DEFAULT_OPTS"
        "--preview-window=right,wrap"
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
    #  - Missing or empty
    #  - Older than binary
    #  - Older than this file
    #
    # -s rather than -f, as in util/luarocks.rc.zsh. A failed `zoxide init`
    # still leaves the empty file that >| created, and -f accepted it, so the
    # shell went on sourcing nothing until the binary or this file changed.
    if [[ ! -s "$__init_cache" ]] ||
        [[ "$__init_cache" -ot "$commands[zoxide]" ]] ||
        [[ "$__init_cache" -ot "$__this_file" ]]; then
        print -u2 "Regenerating zoxide source cache"
        zoxide init zsh --cmd cd --hook pwd >| "$__init_cache"
    fi

    source "$__init_cache"
}
__init_zoxide
unset -f __init_zoxide

unset __this_file
