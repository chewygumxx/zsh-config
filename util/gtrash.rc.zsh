#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/gtrash.rc.zsh
#
#

#
# Zsh source file to prepare interactive utility 'gtrash'.
#
# https://github.com/umlx5h/gtrash
# https://github.com/umlx5h/gtrash/blob/main/doc/configuration.md
#

[[ -o interactive ]] || return
(($+commands[gtrash])) || return

# -----------------
# Validate Wrapper
# -----------------

if ((!$+functions[gtrash])); then
    print -u2 -f "%s: [%s] %s\n" \
        "${(D)${${(%):-%N}:a}}" "WARN" \
        "Unable to resolve gtrash wrapper function"
fi

# ------
# Alias
# ------

# Takes precedence on purpose. rc/alias.rc.zsh defines del as trash-put on
# Termux, and util/ is sourced after rc/, so gtrash wins wherever both exist.
alias del="gtrash put"
alias del-undo="gtrash restore-group"
