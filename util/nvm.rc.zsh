#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/nvm.rc.zsh
#
#
# Node Version Manager
#

[[ -o interactive ]] || return
[[ -v TERMUX_VERSION ]] && return

export NVM_DIR="$XDG_DATA_HOME/nvm"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# --no-use    Load nvm only when called
#
# Tested without negation. `-s` is true when the file exists and is non-empty,
# so `! -s` sourced nvm.sh precisely when it was absent and skipped it whenever
# it was actually present: nvm never loaded, and the only symptom was a `no such
# file or directory` error on machines without nvm installed.
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" --no-use
