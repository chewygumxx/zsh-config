#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/zsh_dirs.env.zsh
#
#

# The XDG variables are supplied by systemd, as the sister file
# ~/.config/environment.d/base.conf, and systemd's user environment is not
# applied in every context: a bare TTY login, a rescue shell or a container can
# all leave them unset. Without a fallback every path below collapses to a
# root-relative one such as /zsh, and the mkdir -p at the foot of this file then
# fails with permission denied on every single shell start.
#
# The cache fallback deliberately mirrors the non-standard location set in
# base.conf rather than the XDG default of ~/.cache, so that an unset variable
# cannot silently strand a second cache tree elsewhere.
# The source directories follow ZDOTDIR, which is what zsh itself used to find
# .zshenv and .zshrc, so a checkout sourced from anywhere loads its own rc, util,
# func, wrap and spec files rather than whichever copy happens to live under
# XDG_CONFIG_HOME. The data directories below deliberately do not follow it:
# caches, plugins and history are per-user state, not part of the checkout.
zsh_conf="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
zsh_cache="${XDG_CACHE_HOME:-$HOME/.local/cache}"
zsh_share="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
zsh_state="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"

# Declared and assigned as a single statement on purpose. Split across two, the
# subscripted keys below are only valid once `typeset -gA` has actually run, so
# `zsh -n` (which parses without executing) misreads them as a direct array
# assignment and rejects the file. Combined, it parses and this file needs no
# exemption from the lint:syntax task.
typeset -gA zsh_dirs=(
    [conf]="$zsh_conf"
    [env]="$zsh_conf/env"

    [comp]="$zsh_conf/comp"
    [func]="$zsh_conf/func"
    [wrap]="$zsh_conf/wrap"

    [rc]="$zsh_conf/rc"
    [util]="$zsh_conf/util"
    [spec]="$zsh_conf/spec"

    [cache]="$zsh_cache/zsh"
    [cache_comp]="$zsh_cache/zsh/completions"
    [cache_init]="$zsh_cache/zsh/init"
    [cache_zstylecomp]="$zsh_cache/zsh/zstylecomp"
    [cache_zvm]="$zsh_cache/zsh/zsh-vi-mode"

    [share]="$zsh_share"
    [share_func]="$zsh_share/functions"
    [share_comp]="$zsh_share/completions"
    [plugin]="$zsh_share/plugins"

    [state]="$zsh_state"
)

init_dirs="$zsh_cache/.zsh_dirs_initialised"
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
unset init_dirs zsh_conf zsh_cache zsh_share zsh_state

# Shared validator for every consumer of this array. It is defined here, beside
# the declaration, so that anything sourced after .zshenv can rely on it being
# present exactly whenever zsh_dirs itself is. Callers pass a label for the
# diagnostic followed by the keys they intend to read:
#
#   zsh_dirs_require "$__this_file" rc util || return 1
#
function zsh_dirs_require() {
    emulate -L zsh

    local caller="$1"
    shift

    if [[ ! -v zsh_dirs ]]; then
        print -u2 -f '%s: [%s] %s\n' "$caller" "CRITICAL" \
            "Variable not set: zsh_dirs"
        return 1
    fi

    if [[ ! "${(t)zsh_dirs}" == association* ]]; then
        print -u2 -f '%s: [%s] %s\n' "$caller" "CRITICAL" \
            "Variable is not an associative array: zsh_dirs"
        return 1
    fi

    local key
    local -i err=0

    for key in "$@"; do
        if [[ ! -v zsh_dirs[$key] ]]; then
            print -u2 -f '%s: [%s] %s\n' "$caller" "ERROR" \
                "zsh_dirs key '$key' not set"
            err=1
            continue
        fi

        if [[ ! -d "${zsh_dirs[$key]}" ]]; then
            print -u2 -f '%s: [%s] %s\n%s\n' "$caller" "ERROR" \
                "zsh_dirs key '$key' is not a directory:" \
                "zsh_dirs[$key]=${(qqq)zsh_dirs[$key]}"
            err=1
        fi
    done

    return $err
}
