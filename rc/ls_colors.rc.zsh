#!/bin/false
# vim: expandtab:shiftwidth=4

# 
# 
# ~/.config/zsh/rc/ls_colors.rc.zsh
# 
# 

#
# Provides for `rc/completion.rc.zsh` and `rc/util/eza.rc.zsh`
#

autoload -Uz colors && colors

typeset -Tg LS_COLORS ls_colors ':'
ls_colors=(
    "di=$color[bold];$color[blue]"      # Directory
    "fi=$color[none]"                   # Ordinary file
    "ex=$color[bold];$color[green]"     # Executable

    "so=$color[bold];$color[red]"       # Socket
    "pi=$color[yellow]"                 # Named pipe (FIFO)
    "bd=$color[bold];$color[yellow]"    # Block device
    "cd=$color[bold];$color[yellow]"    # Character device

    "ln=$color[italic];$color[cyan]"    # Symlink
    "or=$color[italic];$color[blink];$color[reverse];$color[red]"   # Broken symlink

    "tc=$color[faint];$color[magenta]"   # Filetype trailing character
)

# Archive
for ext in "7z" "gz" "rar" "tar" "zip" "xz"; do
    ls_colors+=("*.$ext=$color[red]")
done

# Audio
for ext in "flac" "m4a" "mka" "mp2" "mp3" "ogg"; do
    ls_colors+=("*.$ext=$color[italic];$color[magenta]")
done

# Document
for ext in "pdf" "doc" "docx"; do
    ls_colors+=("*.$ext=$color[cyan]")
done

# Image
for ext in "avif" "bmp" "gif" "ico" "jfif" "jpg" "jpeg" "png" "svg" "tif" "tiff" "webp" "xcf"; do
    ls_colors+=("*.$ext=$color[magenta]")
done

# Source
for ext in "css" "js" "lua" "py" "rs" "sql" "styl" "tsx" "zsh" "zshrc" "zshenv"; do
    ls_colors+=("*.$ext=$color[yellow]")
done

# Video
for ext in "avi" "m4v" "mkv" "mov" "mp4" "mpeg" "mpg" "webm"; do
    ls_colors+=("*.$ext=$color[bold];$color[magenta]")
done

typeset -gx  LS_COLORS
typeset -gx ZLS_COLORS="$LS_COLORS"
typeset -gx EZA_COLORS="$LS_COLORS"
