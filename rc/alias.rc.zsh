#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/alias.rc.zsh
#
#

#
# Aliases may also be grouped by the zsh-als plugin, which spec/zsh-als.spec.zsh
# declares and currently leaves disabled. There is no func/als.
#

local __this_file="${(D)${${(%):-%N}:A}}"

setopt aliases

# Prompt before overwriting
alias cp="cp --interactive"
alias mv="mv --interactive"

# Human readable
alias df='df --human-readable'
alias du='du --block-size=1K'
alias free='free --mebi'

# Show colour and case-insensitive
alias grep='grep --color=auto -i'

# Fix for bash/zsh completion when executing aliases via sudo
# https://wiki.archlinux.org/title/Sudo#Passing_aliases
alias sudo="sudo "
(($+commands[nvim])) && () {
    local alias
    for alias in e ed edit v vi vim nivm hx kak nano emacs; do
        alias "$alias=nvim"
    done
}

# Git
#
# ga and gs are provided by func/ga and func/gs, which carry the same commands
# behind a $+commands[git] guard. Aliases are expanded at parse time, before the
# shell looks for a function of the same name, so defining them here made both
# of those autoloaded functions permanently unreachable dead code.
#
# gs overwrites 'gs' of ghostscript. Never use it.

(($+commands[gh])) && alias gist='gh gist create'

(($+commands[yazi])) && alias y=yazi

# Proton Pass
(($+commands[pass-cli])) && alias pass='pass-cli'

# SQLite
(($+commands[sqlite3])) && alias sqlite='sqlite3'

# Package Manager
#
# pacman is routed through yay by wrap/pacman. It was an alias here, which
# `alias sudo="sudo "` above expanded after sudo as well, handing yay a root
# invocation it refuses.

if (($+commands[kdeconnect-cli])); then
    alias kdecon="kdeconnect-cli --device 1396134ad80c4647aa7c6b1f76d823e3"
    alias kdecon-clip="kdecon --send-clipboard"
fi

# Network
(($+commands[impala])) && alias impala='sudo impala'
(($+commands[bluetui])) && alias bt="bluetui"

if [[ -v TERMUX_VERSION ]]; then
    # Print Dimensions
    alias st='stty size'

    # Package Manager
    alias pki="pkg install"
    alias pks="pkg search"

    # Clipboard
    alias wl-copy="termux-clipboard-set"
    alias wl-paste="termux-clipboard-get"

    (($+commands[trash-put])) && alias del="trash-put"
fi
