#!/usr/bin/env zsh
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/directory.rc.zsh
#
#


# -----
# Home
# -----

hash -d   bin="$HOME/.local/bin"
hash -d share="${XDG_DATA_HOME:-$HOME/.local/share}"

# Home directories (excluding hidden) because who has time for `~/scr` over `~scr`
for dir in "$HOME"/*(/:t); do
    hash -d "${dir:0:3}=$HOME/$dir"
done


# ---------
# Dotfiles
# ---------

# CHEZMOI_* Must be defined from systemd user session start
if [[ -v CHEZMOI_WORKING_TREE ]] && [[ -d "$CHEZMOI_WORKING_TREE" ]]; then
    hash -d dfrepo="$CHEZMOI_WORKING_TREE"
fi

if [[ -v CHEZMOI_SOURCE_DIR ]] && [[ -d "$CHEZMOI_SOURCE_DIR" ]]; then
    hash -d df="$CHEZMOI_SOURCE_DIR"

    [[ -d "$CHEZMOI_SOURCE_DIR/dot_config" ]] &&
        hash -d dfconf="$CHEZMOI_SOURCE_DIR/dot_config"
    [[ -d "$CHEZMOI_SOURCE_DIR/dot_local/bin" ]] &&
        hash -d  dfbin="$CHEZMOI_SOURCE_DIR/dot_local/bin"
fi

# Short-names of ~df/.config/ subdirectories
() {
    local conf_dir="${nameddirs[dfconf]:-${XDG_CONFIG_HOME:-$HOME/.config}}"
    local dir
    for dir in git herdr hypr wezterm yazi zsh; do
        [[ -d "$conf_dir/$dir" ]] && hash -d "${dir:0:4}=$conf_dir/$dir"
    done
    [[ -d "$conf_dir/systemd/user"  ]] && hash -d sysu="$conf_dir/systemd/user"
    [[ -d "$conf_dir/environment.d" ]] && hash -d envd="$conf_dir/environment.d"
}

[[ -d "$XDG_CONFIG_HOME/nvim" ]] && hash -d nvim="$XDG_CONFIG_HOME/nvim"

# --------
# Network
# --------

[[ -d "$HOME/net/firefox" ]] && hash -d ff="$HOME/net/firefox"


# -------
# Termux
# -------

() {
    [[ ! -v TERMUX_VERSION ]] && return
    local emulated="/storage/emulated/0/"

    hash -d pref="${PREFIX:-/data/data/com.termux/files/usr}"
    hash -d emul="$emulated"
    hash -d cgxx="$emulated/_chewygumxx"
    hash -d  edl="$emulated/Download"
    hash -d edoc="$emulated/Documents"
    hash -d epic="$emulated/Pictures"
    hash -d emov="$emulated/Movies"
    hash -d etas="$emulated/Tasker"
    hash -d ecam="$emulated/DCIM/Camera"
    hash -d escr="$emulated/DCIM/Screenshots"
}
