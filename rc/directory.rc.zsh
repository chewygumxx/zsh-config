#!/bin/false
# vim: expandtab:shiftwidth=4

# 
# 
# ~/.config/zsh/rc/directory.rc.zsh
# 
# 

hash -d   bin="$HOME/.local/bin"
hash -d share="$XDG_DATA_HOME"

if (( $+commands[chezmoi] )) && [[ -d "$XDG_DATA_HOME/chezmoi" ]] ; then
    hash -d czroot="$XDG_DATA_HOME/chezmoi"
    hash -d     cz="$XDG_DATA_HOME/chezmoi/dot_config"
fi

for dir in hypr nvim wezterm yazi zsh; do
    if [[ -d "$XDG_CONFIG_HOME/$dir" ]]; then
        hash -d "${dir:0:4}=$XDG_CONFIG_HOME/$dir"
    fi
done
hash -d  hypr="$XDG_CONFIG_HOME/hypr"
hash -d  nvim="$XDG_CONFIG_HOME/nvim"
hash -d   wez="$XDG_CONFIG_HOME/wezterm"
hash -d  yazi="$XDG_CONFIG_HOME/yazi"
hash -d   zsh="$XDG_CONFIG_HOME/zsh"

(( $+commands[firefox] )) && hash -d ff="$HOME/net/firefox"

if [[ -v TERMUX_VERSION ]]; then
    hash -d pref="$PREFIX"
    hash -d cgxx="/storage/emulated/0/_chewygumxx"
fi
