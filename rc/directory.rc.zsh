#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/directory.rc.zsh
#
#

[[ -o interactive ]] || return
local __this_file="${(D)${${(%):-%N}:A}}"

# -----
# Home
# -----

hash -d bin="$HOME/.local/bin"
hash -d share="${XDG_DATA_HOME:-$HOME/.local/share}"
() {
    emulate -L zsh
    setopt local_options no_glob_dots

    # Keys remain the first three characters of each $HOME subdirectory, and are
    # lengthened one character at a time only where that would collide with a
    # key already assigned. Previously every key was a bare ${dir:0:3}, so two
    # directories sharing a three-character prefix (Docker and Documents, say)
    # silently overwrote one another's hash -d entry, and which of the two
    # survived depended on glob order.
    #
    # Existing shortcuts are unaffected whenever prefixes are already distinct.
    #
    # (N) matters here because no_glob_dots is set just above: a $HOME holding
    # only dot-directories matches nothing and would otherwise abort the loop
    # with `no matches found`.
    local dir key
    local -A taken

    for dir in "$HOME"/*(N/:t); do
        key="${dir:0:3}"

        # Grow the key until it is unique, stopping once the whole name is used.
        while [[ -n "${taken[$key]}" && "$key" != "$dir" ]]; do
            key="${dir:0:$((${#key} + 1))}"
        done

        if [[ -n "${taken[$key]}" ]]; then
            print -u2 -f '%s: [%s] %s\n' "$__this_file" "WARN" \
                "Named directory ~$key is taken by '${taken[$key]}', skipping '$dir'"
            continue
        fi

        taken[$key]="$dir"
        hash -d "$key=$HOME/$dir"
    done
}

# ---------
# Dotfiles
# ---------

# CHEZMOI_* Must be defined from systemd user session start
if [[ -v CHEZMOI_WORKING_TREE && -d "$CHEZMOI_WORKING_TREE" ]]; then
    hash -d dfrepo="$CHEZMOI_WORKING_TREE"
fi

if [[ -v CHEZMOI_SOURCE_DIR && -d "$CHEZMOI_SOURCE_DIR" ]]; then
    hash -d df="$CHEZMOI_SOURCE_DIR"

    [[ -d "$CHEZMOI_SOURCE_DIR/dot_config" ]] &&
        hash -d dfconf="$CHEZMOI_SOURCE_DIR/dot_config"
    [[ -d "$CHEZMOI_SOURCE_DIR/dot_local/bin" ]] &&
        hash -d dfbin="$CHEZMOI_SOURCE_DIR/dot_local/bin"
fi
() {
    emulate -L zsh

    local cfg_dir="${nameddirs[dfconf]:-${XDG_CONFIG_HOME:-$HOME/.config}}"
    local -A cfg_dirs
    cfg_dirs=(
        [envd]="$cfg_dir/environment.d"
        [git]="$cfg_dir/git"
        [herd]="$cfg_dir/herdr"
        [hypr]="$cfg_dir/hypr"
        [nvim]="$cfg_dir/nvim"
        [sysu]="$cfg_dir/systemd/user"
        [wez]="$cfg_dir/wezterm"
        [yazi]="$cfg_dir/yazi"
        [zsh]="$cfg_dir/zsh"
    )
    [[ -d "$HOME/dev/nvim-config" ]] &&
        cfg_dirs[nvim]="$HOME/dev/nvim-config"
    [[ -d "$HOME/dev/zsh-config" ]] &&
        cfg_dirs[zsh]="$HOME/dev/zsh-config"

    local name dir
    for name dir in "${(@kv)cfg_dirs}"; do
        [[ -d "$dir" ]] && hash -d "$name=$dir"
    done
}

# --------
# Network
# --------

[[ -d "$HOME/net/firefox" ]] && hash -d ff="$HOME/net/firefox"
() {
    [[ ! -v TERMUX_VERSION ]] && return
    # No trailing slash. With one, ~emul never matched a path for %~ in the
    # prompt, and every name below held a doubled slash, as in
    # /storage/emulated/0//Download, so none of them ever matched either.
    local emulated="/storage/emulated/0"

    hash -d pref="${PREFIX:-/data/data/com.termux/files/usr}"
    hash -d emul="$emulated"
    hash -d cgxx="$emulated/_chewygumxx"
    hash -d edl="$emulated/Download"
    hash -d edoc="$emulated/Documents"
    hash -d epic="$emulated/Pictures"
    hash -d emov="$emulated/Movies"
    hash -d etas="$emulated/Tasker"
    hash -d ecam="$emulated/DCIM/Camera"
    hash -d escr="$emulated/DCIM/Screenshots"
}
