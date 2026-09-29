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
# Setting ZDOTDIR alone is not enough. env/zsh_dirs.env.zsh derives its cache,
# data and state trees from the XDG variables rather than from ZDOTDIR, so every
# one of them is set, and none can be inherited from the calling shell and point
# at the live tree. sandbox_zsh_bare below is the deliberate exception.
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

    local candidate

    # An explicitly set ZSH_TEST_PLUGIN_DIR is authoritative, with no fallback.
    # Quietly reaching for the live cache when the named directory turns out to
    # be unusable would test against different plugins than the caller asked
    # for and report success either way.
    if [[ -n "$ZSH_TEST_PLUGIN_DIR" ]]; then
        candidate="$ZSH_TEST_PLUGIN_DIR"
    else
        candidate="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
    fi

    [[ -d "$candidate" ]] || return 1

    # A directory that exists but holds no clones is not a usable cache, and
    # this check is the whole point of the function. Accepting an empty one
    # leaves rc/plugin.rc.zsh and rc/completion.rc.zsh to clone every plugin
    # over the network from inside the sandbox: slow, dependent on the network
    # rather than on the code under test, and silent about it.
    #
    # Evaluated through an array because [[ ]] performs no filename generation,
    # so a glob qualifier written inside it is never expanded.
    local -a clones=("$candidate"/*(N/))
    ((${#clones})) || return 1

    print -r -- "$candidate"
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

    # 0755 throughout, and never group or world writable. compinit audits every
    # directory on fpath whenever the completion dump is stale, so nothing the
    # fixture makes should be one it has cause to skip.
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
    #
    # A test that needs more in the environment declares a local SANDBOX_ENV
    # array of NAME=value words, which reaches this function through dynamic
    # scope and is appended after the defaults, so it can also override them.
    # Unset, the plain $SANDBOX_ENV expansion yields no words at all.
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
        $SANDBOX_ENV \
        zsh "$@"
}

#
# Start the sandbox once and discard both streams.
#
# A new sandbox has an empty cache, so its first interactive start legitimately
# reports what it is populating: env/zsh_dirs.env.zsh announces "Creating zsh
# directories", and util/chezmoi.rc.zsh, util/luarocks.rc.zsh and
# util/zoxide.rc.zsh each announce the cache they are regenerating. All four are
# by design, and all four correctly go to stderr rather than stdout.
#
# Throwing that first start away is what lets the suite treat anything a later
# start reports as a genuine fault. The exit status is deliberately not
# propagated: whether the configuration really loaded is what the assertions
# themselves are for, and failing setup here would only obscure them.
#
function sandbox_warm() {
    emulate -L zsh

    sandbox_zsh "$1" -i -c exit > /dev/null 2>&1

    return 0
}

#
# Run zsh in a sandbox and print only what it wrote to stderr, discarding
# stdout. The two startup assertions are each about one specific stream, so
# they have to be captured apart.
#
function sandbox_zsh_stderr() {
    emulate -L zsh

    # The order is the mechanism, not a mistake, so C085 is suppressed. 2>&1
    # first points stderr at wherever stdout currently goes, which is the
    # caller's pipe; only then is stdout sent to /dev/null. Reversed, both
    # streams would end up discarded and every assertion would see nothing and
    # pass.
    # shuck: disable=C085
    sandbox_zsh "$@" 2>&1 1> /dev/null
}

#
# Run zsh in a sandbox and print only what it wrote to stdout.
#
function sandbox_zsh_stdout() {
    emulate -L zsh

    sandbox_zsh "$@" 2> /dev/null
}

#
# Run zsh against a sandbox with no XDG variable set at all, as a bare TTY
# login, a rescue shell or a container can leave it. Only HOME, PATH, TERM,
# SHELL and ZDOTDIR are passed, so every XDG fallback in the configuration is
# exercised. The fallbacks name the same directories sandbox_create made.
#
function sandbox_zsh_bare() {
    emulate -L zsh

    local root="$1"
    shift

    env -i \
        HOME="$root" \
        PATH="$PATH" \
        TERM="${TERM:-dumb}" \
        SHELL="${commands[zsh]:-/usr/bin/zsh}" \
        ZDOTDIR="$root/.config/zsh" \
        zsh "$@"
}

#
# Copy the shell sources of this checkout to a directory of the given name
# under the sandbox, and print its path.
#
# The sandbox otherwise links the checkout itself, which suits every test that
# only reads it. A copy is for the tests that need the configuration to live
# somewhere particular, such as a directory whose name is itself a trap, or
# that need a stray file beside the tracked ones, which must never be written
# into the real checkout.
#
function sandbox_copy_config() {
    emulate -L zsh

    local root="$1"
    local name="$2"

    [[ -n "$root" && -d "$root" && -n "$name" ]] || return 1

    local dest="$root/$name"

    mkdir -p -m 0755 -- "$dest" || return 1

    cp -R -- \
        "$ZSH_CONFIG_ROOT"/.zshenv \
        "$ZSH_CONFIG_ROOT"/.zshrc \
        "$ZSH_CONFIG_ROOT"/{env,rc,util,func,wrap,spec,comp} \
        "$dest"/ || return 1

    print -r -- "$dest"
}
