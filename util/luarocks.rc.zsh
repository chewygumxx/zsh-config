#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/luarocks.rc.zsh
#
#
# https://luarocks.org/docs
# https://github.com/luarocks/luarocks/blob/main/docs/index.md
#

[[ -o interactive ]] || return
(($+commands[luarocks])) || return

# Captured out here, since $0 inside the function below is its own name.
local __this_file="$0"

zsh_dirs_require "${(D)__this_file}" cache_init || return 1
() {
    # Declared inside a function, so version and init_cache, both generic
    # names, can no longer overwrite and then unset globals of the same name.
    local version="5.1"
    local init_cache="$zsh_dirs[cache_init]/luarocks$version.init.zsh"

    # Regenerate init cache if either:
    #  - missing
    #  - older than binary
    #  - older than this file
    if [[ ! -s "$init_cache" ]] ||
        [[ "$init_cache" -ot "$commands[luarocks]" ]] ||
        [[ "$init_cache" -ot "$__this_file" ]]; then
        print -u2 "Regenerating luarocks source cache"

        # Only the LUA_PATH and LUA_CPATH exports are kept. `luarocks path`
        # also prints `export PATH='...'` holding the entire PATH of whichever
        # shell happened to run it, and sourcing that replaced the PATH of every
        # later shell with a stale snapshot, discarding anything the parent
        # environment had added since.
        #
        # The rock bin directories are added to the live path instead, and only
        # those not already on it, so a system directory such as /usr/bin is
        # never moved ahead of the entries env/base.env.zsh puts first.
        local -a exports bin_dirs
        exports=(
            ${(M)${(f)"$(command luarocks --lua-version $version path)"}:#export LUA_*}
        )
        bin_dirs=(
            ${(s.:.)"$(command luarocks --lua-version $version path --lr-bin)"}
        )

        {
            print -rl -- $exports
            print -r -- "local -a lr_bin=(${(j: :)${(@qq)bin_dirs}})"
            # Single-quoted on purpose: this line is evaluated when the cache is
            # sourced, against the path of that shell, not this one.
            # shuck: disable=C005
            print -r -- 'path=(${lr_bin:|path} $path)'
        } >| "$init_cache"
    fi

    source "$init_cache"
}
