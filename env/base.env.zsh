#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/base.env.zsh
#
#

#
# Sister of ~/.config/environment.d/base.conf
#

# -U keeps path free of duplicates. This file runs for every zsh, and PATH is
# inherited, so without it each nested shell (a terminal inside Neovim, a
# script with a zsh shebang, a subshell of a subshell) prepended these three
# entries again. -g because .zshenv sources this file from inside a function,
# where a bare typeset would declare a local path and discard it on return.
#
# XDG_DATA_HOME is read with the same fallback env/zsh_dirs.env.zsh uses. Unset,
# the cargo and go entries collapsed to the root-relative /cargo/bin and
# /go/bin.
typeset -gU path
path=(
    "$HOME/.local/bin"
    "${XDG_CACHE_HOME:-$HOME/.local/cache}/.bun/bin"
    "${XDG_DATA_HOME:-$HOME/.local/share}/cargo/bin"
    "${XDG_DATA_HOME:-$HOME/.local/share}/go/bin"
    $path
)
export PAGER="less"
export BROWSER="firefox"
export TERMCMD="wezterm"
export EDITOR="nvim"
export VISUAL="$EDITOR"
