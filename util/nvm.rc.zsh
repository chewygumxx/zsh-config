#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/util/nvm.rc.zsh
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
