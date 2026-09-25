#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/function.rc.zsh
#
#

#
# Appends functions directory to array variable 'fpath', marks zsh function
# files for autoload, and maps aliases to respective wrapper functions.
#
# Dependent upon associative array variable 'zsh_dirs' set in advance.
#

[[ -o interactive ]] || return
local __this_file="${(D)${${(%):-%N}:A}}"

# ---------------------
# Validate Environment
# ---------------------

if [[ ! -v zsh_dirs ]]; then
    print -u2 -f '%s: [%s] %s\n' "$__this_file" "CRITICAL" \
        "Variable not set: zsh_dirs"
    return 1
fi

if [[ ! "${(t)zsh_dirs}" == association* ]]; then
    print -u2 -f '%s: [%s] %s\n' "$__this_file" "CRITICAL" \
        "Variable is not an associative array: zsh_dirs"
    return 1
fi

local dir err=0
for dir in func wrap; do
    if [[ ! -v zsh_dirs[$dir] ]]; then
        print -u2 -f '%s: [%s] %s\n' "$__this_file" "ERROR" \
            "zsh_dirs key '$dir' not set"
        err=1
        continue
    fi
    if [[ ! -d "${zsh_dirs[$dir]}" ]]; then
        print -u2 -f '%s: [%s] %s\n%s\n' "$__this_file" "ERROR" \
            "zsh_dirs key '$dir' is not a directory:" \
            "zsh_dirs[$dir]=${(qqq)zsh_dirs[$dir]}"
        err=1
    fi
done
((err)) && return 1

# ------------------
# Prepare Functions
# ------------------

fpath+=(
    "${zsh_dirs[func]}"
    "${zsh_dirs[wrap]}"
)

autoload -Uz "${zsh_dirs[func]}"/*(N:t)
autoload -Uz "${zsh_dirs[wrap]}"/*(N:t)
