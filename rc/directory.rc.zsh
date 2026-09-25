#!/usr/bin/env zsh
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/directory.rc.zsh
#
#

[[ -o interactive ]] || return

# -----
# Home
# -----

hash -d bin="$HOME/.local/bin"
hash -d share="${XDG_DATA_HOME:-$HOME/.local/share}"
() {
    emulate -L zsh
    setopt local_options no_glob_dots

    local dir
    for dir in "$HOME"/*(/:t); do
        hash -d "${dir:0:3}=$HOME/$dir"
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
    local emulated="/storage/emulated/0/"

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
