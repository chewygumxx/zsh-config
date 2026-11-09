#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/zsh/env/tools.env.zsh
#
#

#
# Per-tool XDG relocation, for every zsh invocation
#
# This used to be rc/environment.rc.zsh, read by interactive shells only, so a
# script, a cron job or `ssh host cmd` saw none of it: gpg looked in ~/.gnupg,
# cargo and go installed into ~/.cargo and ~/go, and so on, diverging from the
# interactive shell in exactly the places where state lives.
#
# Exported unconditionally rather than behind a $+commands check per tool. A
# variable naming a directory of an absent tool costs nothing, whereas the first
# $+commands lookup hashes every PATH directory, a price every non-interactive
# shell would otherwise pay.
#
# Every XDG variable is read with the same fallback env/zsh_dirs.env.zsh uses.
# Unset, each path here collapsed to a root-relative one such as /gnupg.
#
# GOROOT is no longer set. The go command locates its own root, and a fixed
# GOROOT is wrong the moment GOTOOLCHAIN selects a different toolchain.
# No anonymous function scopes the four helpers below, because shuck format
# deletes every comment above an anonymous function that opens a file, this
# header included. They are unset at the foot instead.
#

: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_{CACHE,CONFIG,DATA,STATE}_HOME

# Android
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"

# .NET
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export NUGET_PACKAGES="$XDG_DATA_HOME/NuGetPackages"

# Bun. With XDG_CACHE_HOME set, global packages and their links default to
# $XDG_CACHE_HOME/.bun, so clearing the cache uninstalled them. Bun 1.4.2
# ignores globalDir and globalBinDir in a global .bunfig.toml; only these
# variables move them. The download cache stays under XDG_CACHE_HOME.
export BUN_INSTALL_GLOBAL_DIR="$XDG_DATA_HOME/bun/global"
export BUN_INSTALL_BIN="$XDG_DATA_HOME/bun/bin"

# Codex keeps config, credentials, databases, transcripts and its daemon in one
# root, so it lives in ~/.local/var, the dotfiles home directory specification's
# place for inseparable application data. Not an XDG variable: no fallback.
export CODEX_HOME="$HOME/.local/var/codex"

# Console Do Not Track, https://consoledonottrack.com, honoured by gh among
# many others. 1, as the convention specifies and as wrap/claude defaults it;
# it was "true" here.
export DO_NOT_TRACK=1

# GitHub
export GH_TELEMETRY="false"

# GnuPG
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$XDG_DATA_HOME/go/bin"

# Gradle
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"

# npm, whose cache and debug logs (cache/_logs) otherwise land in ~/.npm
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

# Parallel
export PARALLEL_HOME="$XDG_DATA_HOME/parallel"

# Perl
export PERL_CPANM_HOME="$XDG_CACHE_HOME/cpanm"

# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"

# Rust
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

# SQLite
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite/history"
