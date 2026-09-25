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
local spec
for spec in $zsh_dirs[spec]/*(N.); do

    () {
        local slug enabled
        source "$spec" 2> /dev/null

        [[ "$enabled" == "false" ]] && continue

        if [[ ! -v slug ]]; then
            print -u2 -f '%s: [%s] %s' "$__this_file" "ERROR" \
                "No slug provided within: $spec"
            continue
        fi

        local plugin="${slug#*/}"

        if [[ ! -d "$zsh_dirs[plugin]/$plugin" ]]; then
            command git clone \
                "https://github.com/$slug.git" \
                "$zsh_dirs[plugin]/$plugin"
        fi

        source "$zsh_dirs[plugin]/$plugin/$plugin.plugin.zsh" 2> /dev/null
    }
done
