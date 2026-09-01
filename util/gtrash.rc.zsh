#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:

#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/util/gtrash.rc.zsh
#
#

#
# Zsh source file to prepare interactive utility 'gtrash'.
#
# https://github.com/umlx5h/gtrash
# https://github.com/umlx5h/gtrash/blob/main/doc/configuration.md
#

[[ -o interactive     ]] || return
(( $+commands[gtrash] )) || return


# -----------------
# Validate Wrapper
# -----------------

if (( ! $+functions[gtrash] )); then
    print -u2 -f "%s: [%s] %s\n" \
        "${(D)${${(%):-%N}:a}}" "WARN" \
        "Unable to resolve gtrash wrapper function"
fi


# ------
# Alias
# ------

alias del="gtrash put"
alias del-undo="gtrash restore-group"
