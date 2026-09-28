#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/env/ssh.env.zsh
#
#

# A socket that ssh itself set up for a forwarded agent is left alone. This file
# runs for every zsh, so the export below used to replace the forwarded agent
# of an `ssh -A` login with the local Proton Pass socket, which does not exist
# on the remote end.
#
# XDG_RUNTIME_DIR is not set in every context, and without a fallback the
# socket path collapsed to /ssh-agent-protonpass.socket. /run/user/$UID is
# where systemd-logind creates it.
if [[ -z "$SSH_CONNECTION" || -z "$SSH_AUTH_SOCK" ]]; then
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}"
    SSH_AUTH_SOCK+="/ssh-agent-protonpass.socket"
fi
