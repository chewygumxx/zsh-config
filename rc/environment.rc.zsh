#!/bin/false
# vim: expandtab:shiftwidth=4:filetype=zsh:

# 
# 
# ~chewygumxx/dotfiles.git
# ::: :/dot_config/zsh/rc/util/environment.rc.zsh
# 
# 

#
# Interactive Shell Environment Variables
#

[[ -o interactive      ]] || return


# Android
if (( $+commands[adb] )); then 
    export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
fi

if (( $+commands[dotnet] )); then 
    export DOTNET_CLI_HOME="$XDG_DATA_HOME"/dotnet
    export NUGET_PACKAGES="$XDG_CACHE_HOME"/NuGetPackages
fi

# GitHub
if (( $+commands[gh] )); then
    export GH_TELEMETRY="false"
    export DO_NOT_TRACK="true"
fi

# GnuPG
if (( $+commands[gpg] )); then
    export GNUPGHOME="$XDG_DATA_HOME/gnupg"
fi

# Go
if (( $+commands[go] )); then
    export GOROOT="/usr/lib/go"
    export GOPATH="$XDG_DATA_HOME/go"
    export GOBIN="$XDG_DATA_HOME/go/bin"
fi

# Gradle
if (( $+commands[gradle] )); then
    export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
fi

# Parallel
if (( $+commands[parallel] )); then 
    export PARALLEL_HOME="$XDG_DATA_HOME/parallel"
fi

# Perl
if (( $+commands[cpan] )); then
    export PERL_CPANM_HOME="$XDG_CACHE_HOME/cpanm"
fi

# Python
if (( $+commands[python] )); then
    export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
    export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
fi

# Rust
if (( $+commands[cargo] )); then
    export CARGO_HOME="$XDG_DATA_HOME/cargo"
fi

if (( $+commands[rustup] )); then
    export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
fi

# SQLite
if (( $+commands[sqlite3] )); then
    export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite/history"
fi
