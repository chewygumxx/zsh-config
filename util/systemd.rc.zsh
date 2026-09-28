#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/systemd.rc.zsh
#
#
[[ -o interactive ]] || return
(($+commands[systemctl])) || return

setopt aliases

alias sysu="systemctl --user"

# ~sysu and ~envd are defined by rc/directory.rc.zsh alone. They used to be
# defined here as well, and since util/ is sourced last, these unconditional
# copies replaced the ones there: that file prefers the chezmoi source tree and
# only names a directory that exists, whereas these pointed at the deployed
# tree regardless, and at /systemd/user whenever XDG_CONFIG_HOME was unset.
