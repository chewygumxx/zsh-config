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
# Appends the func and wrap directories to array variable 'fpath' and marks the
# files in them for autoload.
#
# No aliases are created here. Files in wrap/ are named directly after the
# command they wrap, and a defined function already takes precedence over a
# same-named external binary, so no alias is needed to make the wrapper win.
#
# Dependent upon associative array variable 'zsh_dirs' set in advance.
#

[[ -o interactive ]] || return
local __this_file="${(D)${${(%):-%N}:A}}"

# ---------------------
# Validate Environment
# ---------------------

zsh_dirs_require "$__this_file" func wrap || return 1

# ------------------
# Prepare Functions
# ------------------

fpath+=(
    "${zsh_dirs[func]}"
    "${zsh_dirs[wrap]}"
)

autoload -Uz "${zsh_dirs[func]}"/*(N:t)
autoload -Uz "${zsh_dirs[wrap]}"/*(N:t)
