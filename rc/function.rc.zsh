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

# Collected first and autoloaded only when there is something to load. Given no
# names at all, `autoload -Uz` lists every function already marked for autoload,
# on stdout, which an empty func/ or wrap/ would have triggered.
#
# [^.]* and the . qualifier restrict this to regular, visible files. .zshrc sets
# globdots, so a bare * also matched a .keep or an editor's swap file, and would
# have matched a subdirectory, each of which became a function definition that
# could never load.
local -a __function_names=(
    "${zsh_dirs[func]}"/[^.]*(N.:t)
    "${zsh_dirs[wrap]}"/[^.]*(N.:t)
)
(($#__function_names)) && autoload -Uz -- $__function_names
