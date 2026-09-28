#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/chezmoi.rc.zsh
#
#

#
# Zsh source file to prepare interactive utility 'chezmoi'
# Optionally dependent on configurable wrapper function
#

[[ -o interactive ]] || return
(($+commands[chezmoi])) || return

# -----------------
# Validate Wrapper
# -----------------

if ((!$+functions[chezmoi])); then
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

# Captured out here, where %N names this file. Inside the function below it
# names the function, `(anon)`, so the freshness test compared against a path
# that never exists: -ot is false whenever either file is missing, and an edit
# to this file never triggered a rebuild.
local __this_file="${${(%):-%N}:A}"
() {
    local comp_file="$zsh_dirs[cache_comp]/_chezmoi"

    # Regenerate completions cache if either:
    #  - Missing
    #  - Older than chezmoi binary
    #  - Older than this file
    if [[ ! -r "$comp_file" ]] ||
        [[ "$comp_file" -ot "$commands[chezmoi]" ]] ||
        [[ "$comp_file" -ot "$__this_file" ]]; then
        print -u2 "Regenerating chezmoi completion file"
        \builtin command chezmoi completion zsh >| "$comp_file"
    fi
}
# Completions will be available next shell
