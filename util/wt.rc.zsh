#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/wt.rc.zsh
#
#
# Worktrunk git worktree manager
# https://worktrunk.dev/
# https://worktrunk.dev/config/#shell-integration
#

[[ -o interactive ]] || return
(($+commands[wt])) || return

local __this_file="$0"

zsh_dirs_require "${(D)__this_file}" cache_init || return 1

# The init wraps `wt` in a function so `wt switch` can cd this shell, and
# registers lazy completions via compdef, which rc/completion.rc.zsh has
# already provided by the time util/ is sourced. `wt config shell install`
# would append the same eval to .zshrc instead; this file replaces that.
function __init_wt() {
    local __init_cache="$zsh_dirs[cache_init]/wt.init.zsh"

    # Regenerate init cache if:
    #  - Missing or empty
    #  - Older than binary
    #  - Older than this file
    if [[ ! -s "$__init_cache" ]] ||
        [[ "$__init_cache" -ot "$commands[wt]" ]] ||
        [[ "$__init_cache" -ot "$__this_file" ]]; then
        print -u2 "Regenerating wt source cache"
        command wt config shell init zsh >| "$__init_cache"
    fi

    source "$__init_cache"
}
__init_wt
unset -f __init_wt

unset __this_file
