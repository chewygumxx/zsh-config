#!/bin/false
# vim: expandtab:shiftwidth=4:filetype=zsh:

#
#
# ~chewygumxx/dotfiles.git
# ::: :/dot_config/zsh/util/chezmoi.rc.zsh
#
#

#
# Zsh source file to prepare interactive utility 'chezmoi'
# Optionally dependent on configurable wrapper function
#

[[ -o interactive      ]] || return
(( $+commands[chezmoi] )) || return


# -----------------
# Validate Wrapper
# -----------------

if (( ! $+functions[chezmoi] )); then
    print -u2 -n "${(D)${${(%):-%N}:a}}: [WARN] "
    print -u2    "Unable to resolve chezmoi wrapper function"
fi


# ------
# Alias
# ------

setopt aliases

alias cz="chezmoi"
alias cze="cz edit --watch"

alias cza="cz add"
alias czr="cz re-add"
alias czp="cz apply"
alias czf="cz forget"
alias czd="cz destory"

# ------------
# Completions
# ------------

() {
     local comp_file="$zsh_dirs[cache_comp]/_chezmoi"

    # Regenerate completions cache if either:
    #  - Missing
    #  - Older than chezmoi binary
    #  - Older than this file
    if  [[ ! -r "$comp_file" ]] ||\
        [[ "$comp_file" -ot "$commands[chezmoi]" ]] ||\
        [[ "$comp_file" -ot "${${(%):-%N}:A}" ]]
    then
        print "Regenerating chezmoi completion file"
        \builtin command chezmoi completion zsh >| "$comp_file"
    fi
}
# Completions will be available next shell
