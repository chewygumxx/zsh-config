#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/tests/_support/autoload.zsh
#
#

#
# Makes the contents of func/ and wrap/ callable from a test.
#
# These files cannot be sourced. Each one is an autoload body with no
# `function name { ... }` wrapper, so sourcing it would run the body in the
# caller instead of defining anything. rc/function.rc.zsh is no help either: it
# returns early on a non-interactive shell. So the two lines that file runs are
# mirrored here.
#

ZSH_CONFIG_ROOT="${${(%):-%N}:A:h:h:h}"

# -U keeps the array unique, so sourcing this file more than once in one zunit
# process cannot stack up duplicate entries.
#
# -g is not optional. zunit sources this file from inside its own `load`
# function, and a bare `typeset` there declares a local, so the global fpath
# would be shadowed and then thrown away on return, leaving every autoload
# reporting "function definition file not found".
typeset -gU fpath
fpath=(
    "$ZSH_CONFIG_ROOT/func"
    "$ZSH_CONFIG_ROOT/wrap"
    $fpath
)

#
# Mark a name in func/ or wrap/ for autoload, replacing any earlier definition.
#
function load_shell_function() {
    emulate -L zsh

    local name="$1"

    [[ -n "$name" ]] || return 1

    # Dropped first so a name already defined by an earlier test, or by the
    # outer interactive shell, cannot mask the file being tested.
    #
    # Written without spaces inside the double parentheses, as the rest of the
    # repository writes it. Spaced out as `(( $+functions[...] ))`, shuck format
    # rewrites it to `(($ + functions[...]))`, which is not the same expression:
    # it is true when the function is absent and false when it is present.
    (($+functions[$name])) && unfunction -- "$name"

    autoload -Uz -- "$name"
}

#
# Put an executable stub earlier on PATH than the real binary, so a wrapper can
# be driven without invoking the tool it wraps. Wrappers in wrap/ reach the
# binary through `command foo`, which honours PATH, so a stub is enough.
#
# The stub prints its own arguments one per line to stdout, and its name and
# argument count to stderr, which is enough to assert on how a wrapper composed
# its call.
#
function stub_command() {
    emulate -L zsh

    local name="$1"
    local dir="$2"

    [[ -n "$name" && -n "$dir" ]] || return 1

    mkdir -p -m 0755 -- "$dir" || return 1

    # Written as sh rather than zsh: a stub wants to start fast and has no
    # reason to read anything of this configuration.
    #
    # The single quotes below are the whole point, so the two C005 warnings
    # about expansions staying literal are suppressed rather than fixed. These
    # are the stub's own parameters and have to reach the file unexpanded;
    # expanding them here would bake this function's arguments into the stub.
    print -r -- '#!/bin/sh' > "$dir/$name" || return 1
    # shuck: disable=C005
    print -r -- 'printf "stub:%s argc:%s\n" "$0" "$#" >&2' >> "$dir/$name"
    # shuck: disable=C005
    print -r -- 'for arg; do printf "%s\n" "$arg"; done' >> "$dir/$name"

    chmod 0755 -- "$dir/$name" || return 1

    path=("$dir" $path)
}
