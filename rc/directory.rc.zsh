#!/usr/bin/env zsh
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/rc/directory.rc.zsh
#
#


# -----
# Home
# -----

hash -d   bin="$HOME/.local/bin"
hash -d share="$XDG_DATA_HOME"

# Home directories (excluding hidden) because who has time for `~/scr` over `~scr`
for dir in "$HOME"/*(/:t); do
    hash -d "${dir:0:3}=$HOME/$dir"
done


# --------------
# Configuration
# --------------

# CHEZMOI_* Must be defined from systemd user session start
if [[ -v CHEZMOI_WORKING_TREE ]] && [[ -d "$CHEZMOI_WORKING_TREE" ]]; then
    hash -d czroot="$CHEZMOI_WORKING_TREE"
    hash -d     cz="$CHEZMOI_SOURCE_DIR"
    hash -d czconf="$CHEZMOI_SOURCE_DIR/dot_config"
fi

for dir in herdr hypr nvim wezterm yazi zsh; do
    if [[ -d "${nameddirs[czconf]:=$XDG_CONFIG_HOME}/$dir" ]]; then
        hash -d "${dir:0:4}=${nameddirs[czconf]:=$XDG_CONFIG_HOME}/$dir"
    fi
done

[[ -d "${nameddirs[czconf]:=$XDG_CONFIG_HOME}/systemd/user" ]] &&
    hash -d sysu="${nameddirs[czconf]:=$XDG_CONFIG_HOME}/systemd/user"
[[ -d "${nameddirs[czconf]:=$XDG_CONFIG_HOME}/environment.d" ]] &&
    hash -d envd="${nameddirs[czconf]:=$XDG_CONFIG_HOME}/environment.d"


# --------
# Network
# --------

[[ -d "$HOME/net/firefox" ]] && hash -d ff="$HOME/net/firefox"


# -------
# Termux
# -------

if [[ -v TERMUX_VERSION ]]; then
    hash -d pref="$PREFIX"
    hash -d emul="/storage/emulated/0/"
    hash -d cgxx="${nameddirs[emul]}/_chewygumxx"
fi
