#!/bin/false
# vim: expandtab:shiftwidth=4:filetype=zsh:

# 
# 
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/util/eza.rc.zsh
# 
# 

#
# Zsh source file to prepare interactive utility 'eza'
# Optionally dependent on configurable wrapper function
#

[[ -o interactive  ]] || return
(( $+commands[eza] )) || return


# -----------------
# Validate Wrapper
# -----------------

if (( ! $+functions[eza] )); then
    print -u2 -n "${(D)${${(%):-%N}:a}}: [WARN] "
    print -u2    "Unable to resolve eza wrapper function"
fi


# --------
# Options
# --------

typeset -ga __eza_opts=(
    "--all"
    "--long"
    "--group-directories-first"
    "--color=always"
    "--hyperlink"
    "--git"
)
typeset -ga __eza_ignore_glob=(
    "[0-9a-f][0-9a-f]"  # .git/objects/* subdirectories
    ".obsidian"
    ".zettel-notes"
    #".git"
)

# --------
# Aliases
# --------

setopt aliases

# Standard
alias l="eza"
alias ll="l --long"
alias lll='ll --long --total-size'

alias ld='l --only-dirs --show-symlinks' # I never use GNU `ld`
alias lld='ll --only-dirs --show-symlinks'
alias llld='lll --only-dirs --show-symlinks'

alias la="l --all"
alias lla="ll --all"
alias llla='lll --all'

# Tree ^-^
alias lt="l --tree" 
alias llt='ll --tree'
alias lllt='lll --tree'

alias ldt='ld --tree'
alias lldt='lld --tree'
alias llldt='llld --tree --follow-symlinks'
    
alias lat="la --tree" 
alias llat='lla --tree'
alias lllat='llla --tree'
