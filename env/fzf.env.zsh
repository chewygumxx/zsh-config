#!/bin/false
# vim: expandtab:shiftwidth=4

# 
# 
# ~/.config/zsh/env/util/fzf.env.zsh
# 
# 


# FZF_DEFAULT_COMMAND
# Populates fzf list with an entry for each newline to stdout.
# Is *NOT* referenced for shell integration; neither keybinds nor completions.
#
#export FZF_DEFAULT_COMMAND="fd --unrestricted . ."

# FZF_DEFAULT_OPTS
# I use it for themes :3
#
__fzf_default_opts=(
    --highlight-line
    --preview-window=right
    --color 'current-fg:#e8e0ff'
    --color 'current-bg:#141337'
    --color 'current-hl:#7408ff'
    --color 'selected-bg:#090a24'
    --color 'selected-fg:#cad6ff'
    --color 'preview-fg:#cad6ff'
    --color 'hl:#7408ff'
    --color 'query:#cad6ff'
    --color 'info:#7408cf'
    --color 'border:#4e4581'
    --color 'separator:#3d3470'
    --color 'pointer:#7408ff'
    --color 'marker:#7408cf'
)
export FZF_DEFAULT_OPTS=${(j: :)__fzf_default_opts}
unset __fzf_default_opts

# FZF_DEFAULT_OPTS_FILE
# This would be perfect for themes.
#
#export FZF_DEFAULT_OPTS_FILE=$XDG_CONFIG_HOME/fzf/opts.env
