#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/claude.env.zsh
#
#

# Temporarily enabled
export CLAUDE_ALT=1

# Herdr also requires this
if [[ -v CLAUDE_ALT ]]; then
    export CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-2"
else
    export CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
fi
