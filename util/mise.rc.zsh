#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/mise.rc.zsh
#
#

#
# Project development environment management
# https://mise.jdx.dev/
#

[[ -o interactive ]] || return
(($+commands[mise])) || return

eval "$(command mise activate zsh)"
