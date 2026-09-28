#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/rc/history.rc.zsh
#
#
[[ -o interactive ]] || return
local __this_file="${(D)${${(%):-%N}:A}}"

zsh_dirs_require "$__this_file" state || return 1

HISTFILE="$zsh_dirs[state]/history"

# HISTSIZE > SAVEHIST, as the zsh manual advises. This used to be the other
# way round, but the file can never hold more than the shell keeps in memory
# once it is rewritten, so the surplus SAVEHIST was never used, and the margin
# is what lets hist_expire_dups_first discard duplicates before unique entries.
HISTSIZE=21000000
SAVEHIST=20000000

# Append each command to the history file as soon as it finishes, rather than
# on shell exit, recording both when it started and how long it ran.
setopt inc_append_history_time

# Despite Zsh documentation of the INC_APPEND_HISTORY_TIME
# inferring a following setopt EXTENDED_HISTORY is redundant, it
# seems (somehow?) it does need to be setopt-ed for timestamping.
setopt extended_history

# Upon SHELL exit: Append to history file, rather than rewrite
#setopt append_history

# Share a live, common history among all active shells
#setopt share_history
