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

zsh_dirs_require "$__this_file" spec plugin || return 1

local spec
for spec in "$zsh_dirs[spec]"/*(N.); do

    () {
        local slug enabled

        # Errors are deliberately not discarded here. Redirecting them to
        # /dev/null meant a spec with a syntax error, or a plugin that failed to
        # load, was skipped in complete silence on every shell start.
        source "$spec"

        [[ "$enabled" == "false" ]] && continue

        # Tested with -z, not -v. The `local slug` above already brings the
        # parameter into existence, so -v is unconditionally true and this
        # branch could never be reached.
        if [[ -z "$slug" ]]; then
            print -u2 -f '%s: [%s] %s\n' "$__this_file" "ERROR" \
                "No slug provided within: $spec"
            continue
        fi

        local plugin="${slug#*/}"
        local plugin_dir="$zsh_dirs[plugin]/$plugin"
        local plugin_file="$plugin_dir/$plugin.plugin.zsh"

        # Installed means the entry point is readable, not merely that the
        # directory exists. A clone interrupted part way leaves the directory
        # behind, and testing -d alone treated that as permanently complete, so
        # the plugin silently never loaded again and was never re-cloned.
        if [[ ! -r "$plugin_file" ]]; then
            if ! command git clone \
                "https://github.com/$slug.git" \
                "$plugin_dir"; then
                print -u2 -f '%s: [%s] %s\n' "$__this_file" "ERROR" \
                    "Failed to clone plugin: $slug"
                continue
            fi
        fi

        if [[ ! -r "$plugin_file" ]]; then
            print -u2 -f '%s: [%s] %s\n' "$__this_file" "ERROR" \
                "Plugin entry point not readable: $plugin_file"
            continue
        fi

        source "$plugin_file"
    }
done
