#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/bat.rc.zsh
#
#
# https://github.com/sharkdp/bat
#

[[ -o interactive ]] || return
(($+commands[bat])) || return

# Command --help Colorisation

# Disabled due to global aliases expanding in the shell case match strings of
# sourced files
#alias -g -- -h='     -h    2>&1	| bat --language=help'
#alias -g -- --help='--help 2>&1	| bat --language=help'

# Commands for which a trailing -h means something other than help, almost
# always human-readable sizes. The rewrite used to apply to every command, so
# `df -h`, `du -h` and `free -h` had their output piped through
# `bat --language=help`. eza is here for its -h, which is --header, and so are
# the aliases util/eza.rc.zsh defines over it.
typeset -ga __bat_help_short_excluded=(
    df du free ls sort numfmt dust duf eza
    l ll lll la lla llla lt llt lllt ld lld llld
)

function _zle_accept_line_help_bat() {
    emulate -L zsh

    if [[ $BUFFER == *\ (-h|--help) ]]; then
        local -a words=(${(z)BUFFER})

        # Precommand modifiers are skipped to reach the command they run, and
        # an alias is followed to whatever it names, so both `sudo df -h` and a
        # df behind an alias are recognised.
        while [[ "$words[1]" == (sudo|command|builtin|nocorrect|noglob|time) ]]; do
            shift words
        done

        local cmd="$words[1]"
        local -i hops=0
        while (($+aliases[$cmd] && hops++ < 10)); do
            cmd="${${(z)aliases[$cmd]}[1]}"
        done

        local -i excluded=0
        ((${__bat_help_short_excluded[(Ie)$cmd]})) && excluded=1
        ((${__bat_help_short_excluded[(Ie)$words[1]]})) && excluded=1

        if [[ "$words[-1]" == --help ]] || ((!excluded)); then
            BUFFER="${BUFFER} 2>&1 | bat --language=help"
        fi
    fi
    zle .accept-line
}
zle -N accept-line _zle_accept_line_help_bat
