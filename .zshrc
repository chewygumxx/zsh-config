#!/usr/bin/env zsh
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

# (N) sets null_glob per pattern. Without it an empty rc/ or util/ raises
# `no matches found`, which aborts the entire array literal below and leaves the
# interactive shell with no aliases, no prompt and no history configuration.
typeset -ga zshrcs
zshrcs=("$zsh_dirs[rc]"/*.rc.zsh(N))

zshrcs=(
    ${(M)zshrcs:#*ls_colors*} # Provides for completion
    ${(M)zshrcs:#*completion*} # Minimise fpath for completion index
    ${(M)zshrcs:#*function*} # Provide function dependencies

    ${zshrcs:#*(ls_colors|completion|function)*}

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
