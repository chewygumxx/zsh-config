#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/mise.env.zsh
#
#

[[ -o interactive ]] && return # util/mise.rc.zsh handles interactive
(($+commands[mise])) || return

path=(
    "$HOME/.local/share/mise/shims"
    $path
)
