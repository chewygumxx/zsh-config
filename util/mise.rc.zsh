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

# Activation prepends mise's tool directories, burying the shadow wrappers in
# ~/.local/bin (e.g. node) behind the binaries they wrap. Unless
# activate_aggressive is set, mise keeps PATH entries added after activation
# in front across its hooks, but rebuilds every entry it saw at activation in
# its original place. So ~/.local/bin is withheld from activation and only
# prepended afterwards; moving it in place would be undone by the next prompt.
path=(${path:#$HOME/.local/bin})
eval "$(command mise activate zsh)"
path=("$HOME/.local/bin" $path)
