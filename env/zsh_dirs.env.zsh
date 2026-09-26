#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/zsh_dirs.env.zsh
#
#

typeset -gA zsh_dirs
zsh_dirs=(
    [conf]="$XDG_CONFIG_HOME/zsh"
    [env]="$XDG_CONFIG_HOME/zsh/env"

    [comp]="$XDG_CONFIG_HOME/zsh/comp"
    [func]="$XDG_CONFIG_HOME/zsh/func"
    [wrap]="$XDG_CONFIG_HOME/zsh/wrap"

    [rc]="$XDG_CONFIG_HOME/zsh/rc"
    [util]="$XDG_CONFIG_HOME/zsh/util"
    [spec]="$XDG_CONFIG_HOME/zsh/spec"

    [cache]="$XDG_CACHE_HOME/zsh"
    [cache_comp]="$XDG_CACHE_HOME/zsh/completions"
    [cache_init]="$XDG_CACHE_HOME/zsh/init"
    [cache_zstylecomp]="$XDG_CACHE_HOME/zsh/zstylecomp"
    [cache_zvm]="$XDG_CACHE_HOME/zsh/zsh-vi-mode"

    [share]="$XDG_DATA_HOME/zsh"
    [share_func]="$XDG_DATA_HOME/zsh/functions"
    [share_comp]="$XDG_DATA_HOME/zsh/completions"
    [plugin]="$XDG_DATA_HOME/zsh/plugins"

    [state]="$XDG_STATE_HOME/zsh"
)

init_dirs="$XDG_CACHE_HOME/.zsh_dirs_initialised"
# Re-mkdir zsh directories if either:
#  - Missing
#  - Older than this file
if ! [[ "$init_dirs" -nt "${0}" ]]; then
    # This file is sourced by .zshenv for every zsh invocation, interactive or
    # not, so anything written to stdout corrupts the stream that scp, rsync,
    # sftp and git over ssh read as protocol data. Report on stderr only.
    print -u2 "Creating zsh directories"
    mkdir -p "${(v)zsh_dirs[@]}"
    touch "$init_dirs"
fi
unset init_dirs
