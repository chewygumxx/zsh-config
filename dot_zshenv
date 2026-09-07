#!/bin/false
# vim: expandtab:shiftwidth=4:filetype=zsh:

#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/dot_zshenv
#
#

#
# Universal Zsh Initialisation
#

typeset -ga zshenvs
zshenvs=(
    "$ZDOTDIR/env/"*.env.zsh
)

() {
    local source
    for source in $zshenvs; do
        source "$source"
    done
}
