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

# Resolved as mise resolves its own data directory. This was once hardcoded
# under $HOME/.local/share, so a relocated XDG_DATA_HOME put a directory on
# PATH that held no shims.
path=(
    "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
    $path
)
