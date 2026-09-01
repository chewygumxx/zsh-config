#!/bin/false
# vim: expandtab:shiftwidth=4

#
#
# ~/.config/zsh/rc/util/luarocks.rc.zsh
#
#

#
# https://luarocks.org/docs
# https://github.com/luarocks/luarocks/blob/main/docs/index.md
#

[[ -o interactive       ]] || return
(( $+commands[luarocks] )) || return

version="5.1"
init_cache="$zsh_dirs[cache_init]/luarocks$version.init.zsh"

# regenerate init cache if either:
#  - missing
#  - older than binary
#  - older than this file
if  [[ ! -s "$init_cache" ]] ||
    [[ "$init_cache" -ot "$commands[luarocks]" ]] ||
    [[ "$init_cache" -ot "${0}" ]]
then
    echo "Regenerating luarocks source cache"
    luarocks --lua-version $version path --bin >| "$init_cache"
fi

source "$init_cache"

unset version init_cache
