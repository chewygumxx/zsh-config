#!/bin/false
# vim: expandtab:shiftwidth=4:filetype=zsh

#
#
# ~chewygumxx/dotfiles.git
# ::: :/dot_config/zsh/rc/function.rc.zsh
#
#

#
# Appends functions directory to array variable 'fpath', marks zsh function
# files for autoload, and maps aliases to respective wrapper functions.
#
# Dependent upon associative array variable 'zsh_dirs' set in advance.
#

[[ -o interactive ]] || return


# ---------------------
# Validate Environment
# ---------------------

if [[ ! -v zsh_dirs ]]; then
    print -u2 "${(D)${${(%):-%N}:A}}: [CRITICAL] Variable not set: zsh_dirs"
    return 1
fi

if [[ ! "${(t)zsh_dirs}" == association* ]]; then
    print -u2 "${(D)${${(%):-%N}:A}}: [CRITICAL] Variable is not an associative array: zsh_dirs"
    return 1
fi

if [[ ! -d "${zsh_dirs[func]}" ]]; then
    print -u2 -f "${(D)${${(%):-%N}:A}}: [ERROR] %s\n" \
        "Variable key is not a directory:" \
        "zsh_dirs=( [func]=${(qqq)zsh_dirs[func]} )"
    return 1
fi


# ------------------
# Prepare Functions
# ------------------

fpath+=(
    "${zsh_dirs[func]}"
    "${zsh_dirs[wrap]}"
)

autoload -Uz "${zsh_dirs[func]}"/*(N:t)
autoload -Uz "${zsh_dirs[wrap]}"/*(N:t)

# Wrapper Functions
() {
    local wrapper
    for wrapper in "${zsh_dirs[func]}"/*-wrapper(N:t); do
        alias -- "${wrapper%-wrapper}=$wrapper"
    done
}
