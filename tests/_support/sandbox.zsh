#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/tests/_support/sandbox.zsh
#
#

#
# Builds a throwaway HOME pointed at this checkout, so the suite never reads or
# writes the live config, cache, history or plugin clones.
#
# Setting ZDOTDIR alone is not enough. env/base.env.zsh and env/ssh.env.zsh
# read XDG_DATA_HOME and XDG_RUNTIME_DIR with no fallback, and
# env/zsh_dirs.env.zsh derives its cache, data and state trees from the XDG
# variables rather than from ZDOTDIR, so every one of them has to be set.
#
# Nothing here exports into the calling shell. zunit runs every test as a
# function inside one process, so an exported variable would leak into each
# later test; sandbox_zsh passes the environment explicitly instead.
#

# Derived from this file rather than from $PWD, so the suite does not depend on
# the directory zunit was invoked from.
ZSH_CONFIG_ROOT="${${(%):-%N}:A:h:h:h}"

# Prefix for every sandbox this file creates. sandbox_destroy refuses to remove
# anything not matching it.
ZSH_SANDBOX_PREFIX="zsh-config-test"

#
# Resolve a directory of existing plugin clones to borrow, so a test run never
# reaches the network. Prints the path, or returns 1 when there is none.
#
function sandbox_plugin_source() {
    emulate -L zsh

    local -a candidates=(
        "$ZSH_TEST_PLUGIN_DIR"
        "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
    )

    local candidate
    for candidate in $candidates; do
        [[ -n "$candidate" && -d "$candidate" ]] || continue

        print -r -- "$candidate"
        return 0
    done

    return 1
}

#
# Create a sandbox tree and print its root.
#
function sandbox_create() {
    emulate -L zsh

    local root
    root="$(mktemp -d -- "${TMPDIR:-/tmp}/$ZSH_SANDBOX_PREFIX.XXXXXXXX")" ||
        return 1

    local config="$root/.config"
    local cache="$root/.local/cache"
    local data="$root/.local/share"
    local state="$root/.local/state"

    # 0755 throughout, and never group or world writable. On the branch where
    # the completion dump is stale, rc/completion.rc.zsh calls compinit with
    # neither -i nor -u, so a loosely permissioned directory anywhere on fpath
    # makes it report insecure directories and, on a terminal, stop to ask.
    chmod 0755 -- "$root" || return 1

    mkdir -p -m 0755 -- \
        "$config" \
        "$cache" \
        "$data/zsh/plugins" \
        "$state" \
        "$root/run" || return 1

    # zsh finds .zshenv and .zshrc through ZDOTDIR, and env/zsh_dirs.env.zsh
    # derives every source directory from it, so this symlink is what puts this
    # checkout under test rather than the live one.
    ln -sfn -- "$ZSH_CONFIG_ROOT" "$config/zsh" || return 1

    # Linked one entry at a time rather than as a single directory symlink.
    # Were the whole directory linked, a plugin that happens to be missing
    # would have rc/plugin.rc.zsh clone it straight into the live cache. This
    # way reads are shared and every write stays inside the sandbox.
    #
    # The (N/) qualifier matches directories only, which also steps over the
    # stray history file that sits in that directory.
    local plugins plugin
    if plugins="$(sandbox_plugin_source)"; then
        for plugin in "$plugins"/*(N/); do
            ln -sfn -- "$plugin" "$data/zsh/plugins/${plugin:t}" || return 1
        done
    fi

    print -r -- "$root"
}

#
# Remove a sandbox created by sandbox_create.
#
function sandbox_destroy() {
    emulate -L zsh

    local root="$1"

    # A recursive delete built from an empty or unexpected variable is the one
    # mistake in this file worth engineering against, so the path has to look
    # like something sandbox_create made before anything is removed.
    [[ -n "$root" && -d "$root" && "${root:t}" == "$ZSH_SANDBOX_PREFIX".* ]] ||
        return 1

    rm -rf -- "$root"
}

#
# Run zsh against a sandbox with a controlled environment. Every argument after
# the root is passed through to zsh.
#
function sandbox_zsh() {
    emulate -L zsh

    local root="$1"
    shift

    # env -i rather than an inherited environment, so a variable set in the
    # caller's shell cannot quietly change the result. PATH is carried over
    # because the load path calls git and various optional binaries.
    env -i \
        HOME="$root" \
        PATH="$PATH" \
        TERM="${TERM:-dumb}" \
        SHELL="${commands[zsh]:-/usr/bin/zsh}" \
        XDG_CONFIG_HOME="$root/.config" \
        XDG_CACHE_HOME="$root/.local/cache" \
        XDG_DATA_HOME="$root/.local/share" \
        XDG_STATE_HOME="$root/.local/state" \
        XDG_RUNTIME_DIR="$root/run" \
        ZDOTDIR="$root/.config/zsh" \
        zsh "$@"
}

#
# Run zsh in a sandbox and print only what it wrote to stderr, discarding
# stdout. The two startup assertions are each about one specific stream, so
# they have to be captured apart.
#
function sandbox_zsh_stderr() {
    emulate -L zsh

    sandbox_zsh "$@" 2>&1 1>/dev/null
}

#
# Run zsh in a sandbox and print only what it wrote to stdout.
#
function sandbox_zsh_stdout() {
    emulate -L zsh

    sandbox_zsh "$@" 2>/dev/null
}
