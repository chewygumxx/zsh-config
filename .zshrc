#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/.zshrc
#
#

#
# Interactive Zsh Shell Initialisation
# Dependent upon associative array variable 'zsh_dirs' set in advance.
#

[[ -o interactive ]] || return

setopt re_match_pcre
setopt interactive_comments
setopt globdots # Match names preceeded by a dot

# This file's own header promises zsh_dirs is set in advance, so check it rather
# than trusting it. The label is expanded inline because .zshrc is sourced at top
# level, where `local` is not available.
zsh_dirs_require "${(D)${${(%):-%N}:A}}" rc util || return 1

# (N) sets null_glob per pattern. Without it an empty rc/ or util/ raises
# `no matches found`, which aborts the entire array literal below and leaves the
# interactive shell with no aliases, no prompt and no history configuration.
typeset -ga zshrcs
zshrcs=("$zsh_dirs[rc]"/*.rc.zsh(N))

# Each pattern is anchored to the final path component with */ and the full
# filename. Matching a bare substring such as *completion* tests the whole
# absolute path, so any config directory containing "completion", "function" or
# "ls_colors" anywhere in its name would misclassify every file beneath it, and
# a file matching two of the three patterns would be sourced twice.
zshrcs=(
    ${(M)zshrcs:#*/ls_colors.rc.zsh} # Provides for completion
    ${(M)zshrcs:#*/completion.rc.zsh} # Minimise fpath for completion index
    ${(M)zshrcs:#*/function.rc.zsh} # Provide function dependencies

    ${zshrcs:#*/(ls_colors|completion|function).rc.zsh}

    "${zsh_dirs[util]}"/*.rc.zsh(N)
)
() {
    local source
    for source in $zshrcs; do

        () {
            source "$source"
        }
    done
}

zle_highlight=('paste:none')
