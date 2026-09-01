#!/bin/false
# vim: expandtab:shiftwidth

#
#
# ~/.config/zsh/rc/util/bat.rc.zsh
#
#

#
# https://github.com/sharkdp/bat
#

[[ -o interactive  ]] || return
(( $+commands[bat] )) || return

# Command --help Colorisation

# Disabled due to global aliases expanding in the shell case match strings of
# sourced files
#alias -g -- -h='     -h    2>&1	| bat --language=help'
#alias -g -- --help='--help 2>&1	| bat --language=help'

function _zle_accept_line_help_bat() {
    if [[ $BUFFER == *\ (-h|--help) ]]; then
        BUFFER="${BUFFER} 2>&1 | bat --language=help"
    fi
    zle .accept-line
}
zle -N accept-line _zle_accept_line_help_bat
