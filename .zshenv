#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/.zshenv
#
#

#
# Universal Zsh Initialisation
#

# Debian and Ubuntu ship an /etc/zsh/zshrc that calls a bare `compinit` before
# $ZDOTDIR/.zshrc is read, and honour this variable as the documented way to
# turn that off. rc/completion.rc.zsh runs compinit itself, with -i and its own
# dump file, so the global call is wasted work at best. At worst, one
# world-writable directory on the system fpath sends it to a prompt that a shell
# with no terminal cannot answer, and it prints
# `compinit: initialization aborted` on every start. It has to be set here,
# since /etc/zsh/zshrc runs before any file under rc/.
skip_global_compinit=1
() {
    # (N) sets null_glob for this pattern alone. Without it an empty or missing
    # env/ directory raises `no matches found`, which aborts the whole
    # assignment and leaves not one environment file sourced.
    #
    # Local, so the list is not left behind in every shell, and ZDOTDIR falls
    # back as env/zsh_dirs.env.zsh does. Unset, as when ~/.zshenv is a link to
    # this file, the glob searched /env and sourced nothing.
    local source
    local -a zshenvs=(
        "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/env/"*.env.zsh(N)
    )

    for source in $zshenvs; do
        source "$source"
    done
}
