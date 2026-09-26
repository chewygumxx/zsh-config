#!/bin/false
# vim: expandtab:shiftwidth=4:filetype=zsh:

#
#
# ~chewygumxx/zsh-config.git
# ::: :/.zshenv
#
#

#
# Universal Zsh Initialisation
#

# (N) sets null_glob for this pattern alone. Without it an empty or missing
# env/ directory raises `no matches found`, which aborts the whole assignment
# and leaves not one environment file sourced.
typeset -ga zshenvs
zshenvs=(
    "$ZDOTDIR/env/"*.env.zsh(N)
)
() {
    local source
    for source in $zshenvs; do
        source "$source"
    done
}
