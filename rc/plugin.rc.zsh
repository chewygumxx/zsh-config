#!/bin/false
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

# Every slug that loaded, in load order, for inspection from the shell and so
# tests/boot.zunit can compare it against spec/ rather than a list of its own.
typeset -ga zsh_plugins_loaded=()

# [^.]* rather than *, and only *.spec.zsh. .zshrc sets globdots, so a bare *
# also matched dotfiles, and an editor swap file left in spec/ was sourced as a
# spec, reporting `No slug provided` on every start.
local spec
for spec in "$zsh_dirs[spec]"/[^.]*.spec.zsh(N.); do

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

        # Cloned when missing or incomplete by func/__plugin_clone, which also
        # validates the slug and reports every failure on stderr itself.
        __plugin_clone "$slug" || continue

        local plugin="${slug#*/}"
        local plugin_file="$zsh_dirs[plugin]/$plugin/$plugin.plugin.zsh"

        # Sourced inside this function, so a plugin's own top-level typeset
        # without -g declares a local that vanishes on return. The plugins in
        # spec/ all declare their globals with -g, as any plugin loaded by a
        # manager such as zinit must, but a new one is worth checking for it.
        source "$plugin_file" && zsh_plugins_loaded+=("$slug")
    }
done
