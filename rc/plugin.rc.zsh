#!/usr/bin/env zsh
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/plugin.rc.zsh
#
#

local __this_file="${(D)${${(%):-%N}:A}}"
() {
    local spec
    for spec in $zsh_dirs[spec]/*(N.); do
        local slug enabled
        source "$spec" 2> /dev/null

        if [[ ! -v slug ]]; then
            print -u2 -f '%s: [%s] %s' "$__this_file" "ERROR" \
                "No slug provided within: $spec"
            continue
        fi

        [[ "$enabled" == "false" ]] && continue

        if [[ ! -d "$zsh_dirs[plugin]/${slug#*/}" ]]; then
            command git clone \
                "https://github.com/$slug.git" \
                "$zsh_dirs[plugin]/${slug#*/}"
        fi

        source "$zsh_dirs[plugin]/$plugin/$plugin.plugin.zsh" 2> /dev/null
    done
}

unset __this_file
