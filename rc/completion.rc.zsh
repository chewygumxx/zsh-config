#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/completion.rc.zsh
#
#
# https://thevaluable.dev/zsh-completion-guide-examples/
#

[[ -o interactive ]] || return
local __this_file="${(D)${${(%):-%N}:A}}"

# Variable ls_colors is declared elsewhere, in rc/ls_colors.rc.zsh
zsh_dirs_require "$__this_file" \
    cache cache_comp cache_zstylecomp comp share_comp plugin func || return 1

# ---------------
# Populate fpath
# ---------------

# Loaded by path rather than through fpath. func/ is deliberately not on fpath
# yet: rc/function.rc.zsh adds it after compinit has indexed a minimal one.
#
# This used to be a local __download_plugin that tested only whether the
# directory existed, so an interrupted clone was treated as complete forever,
# the same fault rc/plugin.rc.zsh had already been fixed for.
autoload -Uz "$zsh_dirs[func]/__plugin_clone"

__plugin_clone "zsh-users/zsh-completions"
# cache_comp holds completion functions generated from a tool's own output, such
# as the _chezmoi that util/chezmoi.rc.zsh writes. It was never on fpath, so
# those files were regenerated faithfully and never once loaded.
fpath+=(
    "$zsh_dirs[share_comp]"
    "$zsh_dirs[comp]"
    "$zsh_dirs[cache_comp]"
    "$zsh_dirs[plugin]/zsh-completions/src"
)

# --------------
# Call compinit
# --------------

# Provides 'menuselect' keymap. Must be loaded before compinit call
zmodload zsh/complist

autoload -Uz compinit
setopt list_types extended_glob
local __zcompdump="${zsh_dirs[cache]}/zcompdump"

# Two faults were corrected here.
#
# The freshness test is evaluated through an array assignment rather than inside
# [[ ]]. Zsh performs no filename generation within [[ ]], so the glob qualifier
# was never expanded there and `-n` simply tested a non-empty literal string:
# the condition was unconditionally true, compinit -C ran on every startup, and
# the dump was never rebuilt no matter how old it became.
#
# It also now measures the dump file itself rather than the cache directory
# holding it, since a directory's mtime only moves when entries are added or
# removed and says nothing about the age of the dump inside it.
#
# Glob explanation:
#   N      Return an empty list if nothing found, instead of an error
#   mh-24  Match only if modified less than 24 hours ago
local -a __zcompdump_fresh=("$__zcompdump"(Nmh-24))

# -i skips any directory compaudit considers insecure, rather than asking what to
# do about it.
#
# Without it, a single world-writable entry anywhere on fpath sends compinit to a
# prompt, and a shell with no terminal to prompt on cannot answer. It then prints
# `not interactive and can't open terminal` followed by
# `compinit: initialization aborted` and gives up, which leaves the shell with no
# completion at all and violates the stderr cleanliness this repo otherwise
# holds to. One system directory outside this checkout is enough to cause it, so
# it is not something a change here can otherwise prevent.
#
# -i rather than -u deliberately: an insecure directory is skipped, not trusted.
#
# The touch after a full run is what keeps the fast path reachable. compinit
# only rewrites the dump when the set of completion files or the zsh version has
# changed, and otherwise sources it as it stands, so its mtime never moved: once
# a day had passed, every later start took the slow path and audited fpath
# again.
if (($#__zcompdump_fresh)); then
    compinit -i -C -d "$__zcompdump"
else
    compinit -i -d "$__zcompdump"
    [[ -f "$__zcompdump" ]] && command touch -- "$__zcompdump"
fi

# ---------------
# Post compinit
# ---------------

# After compinit, not before it. compinit assigns _comp_options outright, so an
# addition made ahead of the call was discarded, and completion only offered
# dotfiles because .zshrc happens to set globdots for the whole shell.
_comp_options+=(globdots)

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$zsh_dirs[cache_zstylecomp]"

zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*:*:-command-:*:*' group-order aliases functions builtins commands
# shuck: disable=C006
zstyle ":completion:*" list-colors $ls_colors

if (($+commands[fzf])); then
    # Must be after `compinit` and before widget wrapping plugins
    # `fast-syntax-highlighting` and `zsh-autosuggestions`.
    # https://github.com/aloxaf/fzf-tab

    # Do not source anything that overwrites <Tab> bindkey.
    # (Don't source junegunn/fzf/completion.zsh, only jungunn/fzf/key-bindings.zsh)

    __plugin_clone "aloxaf/fzf-tab" &&
        source "$zsh_dirs[plugin]/fzf-tab/fzf-tab.plugin.zsh"

    # Escape sequences, like '%F{blue}%d%f', will be ignored by fzf-tab
    zstyle ':completion:*:descriptions' format '[%d]'
    # To allow fzf-tab to capture the unambiguous prefix: Force zsh not to show completion menu
    zstyle ':completion:*' menu no
    # Preview directory's content with eza when completing cd
    # shuck: disable=C005
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --oneline --color=always --group-directories-first --long --git --no-permissions --no-filesize --no-user --no-time --ignore-glob="[0-9a-f][0-9a-f]|.obsidian|.zettel-notes" $realpath'

    # Custom fzf flags
    # By default, fzf-tab does not follow FZF_DEFAULT_OPTS
    zstyle ':fzf-tab:*' use-fzf-default-opts yes
    #zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
    # Switch group using `<` and `>`
    zstyle ':fzf-tab:*' switch-group '<' '>'
else
    zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}[%d]%f'
    zstyle ':completion:*' menu select

    # Dependant on `zmodload zsh/complist` before compinit
    #
    # Bound directly. These used to be queued onto a bindkey_calls array that
    # nothing anywhere in the configuration ever read, so none of the four
    # bindings was ever made.
    bindkey -M menuselect '^h' vi-backward-char
    bindkey -M menuselect '^k' vi-up-line-or-history
    bindkey -M menuselect '^j' vi-down-line-or-history
    bindkey -M menuselect '^l' vi-forward-char
fi
