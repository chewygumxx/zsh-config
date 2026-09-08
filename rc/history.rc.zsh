#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/rc/history.rc.zsh
#
#
[[ -o interactive ]] || return

HISTFILE="$zsh_dirs[state]/history"

# SAVEHIST > HISTSIZE
HISTSIZE=20000000
SAVEHIST=21000000

# Upon shell exit: Append to history file
# Records both time invoked and execution time
setopt inc_append_history_time

# Despite Zsh documentation of the INC_APPEND_HISTORY_TIME        
# inferring a following setopt EXTENDED_HISTORY is redundant, it                                  
# seems (somehow?) it does need to be setopt-ed for timestamping.
setopt extended_history         
                                
# Upon SHELL exit: Append to history file, rather than rewrite
#setopt append_history

# Share a live, common history among all active shells
#setopt share_history
