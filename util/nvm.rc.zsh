#!/bin/false
# vim: expandtab:shiftwidth=4

#
#
# ~/.config/zsh/rc/util/nvm.rc.zsh
#
#

#
# Node Version Manager
#

[[ -o interactive    ]] || return
[[ -v TERMUX_VERSION ]] && return

export NVM_DIR="$XDG_DATA_HOME/nvm"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# --no-use    Load nvm only when called
[[ ! -s "$NVM_DIR/nvm.sh"  ]] && source "$NVM_DIR/nvm.sh" --no-use
