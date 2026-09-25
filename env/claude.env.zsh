#!/usr/bin/env zsh
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/claude.env.zsh
#
#

# Herdr also requires this
: "${CLAUDE_CONFIG_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/claude}"
export CLAUDE_CONFIG_DIR
