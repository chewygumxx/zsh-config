#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/tests/_support/herdr.zsh
#
#

#
# A stand-in herdr for func/__herdr_ids and comp/_herdr.
#
# The stub records its arguments in $dir/herdr.args, answers `api snapshot`
# with $dir/snapshot.json and `completion zsh` with $dir/completion.zsh, and
# exits 64 for anything else. Either file can be overwritten after this has
# run, which is how a test supplies a script or a failure of its own.
#
# The snapshot is the shape a running herdr server returns, cut down to the
# fields the helpers read. It holds two workspaces, one pane in each that is
# an agent, one named and one not, and one plain pane whose cwd lies under
# $HOME, so that both the agent and the cwd descriptions are exercised.
#
function stub_herdr() {
    emulate -L zsh

    local dir="$1"

    [[ -n "$dir" ]] || return 1

    stub_command herdr "$dir" \
        "printf '%s\\n' \"\$@\" > ${(qq)dir}/herdr.args" \
        'case "$*" in' \
        "    *'api snapshot') cat ${(qq)dir}/snapshot.json ;;" \
        "    'completion zsh') cat ${(qq)dir}/completion.zsh ;;" \
        '    *) exit 64 ;;' \
        'esac' || return 1

    print -r -- '{"id":"cli:api:snapshot","result":{"snapshot":{
"workspaces":[
  {"workspace_id":"w1","label":"alpha","number":1},
  {"workspace_id":"w2","label":"beta","number":2}],
"tabs":[
  {"tab_id":"w1:t1","workspace_id":"w1","label":"main"},
  {"tab_id":"w2:t1","workspace_id":"w2","label":"1"}],
"panes":[
  {"pane_id":"w1:p1","tab_id":"w1:t1","workspace_id":"w1",
   "cwd":"/srv/alpha","foreground_cwd":"/srv/alpha"},
  {"pane_id":"w2:p1","tab_id":"w2:t1","workspace_id":"w2",
   "cwd":"'"$HOME"'/dev/beta"},
  {"pane_id":"w2:p2","tab_id":"w2:t1","workspace_id":"w2",
   "cwd":"/srv/beta","foreground_cwd":"/srv/beta/sub"}],
"agents":[
  {"agent":"claude","agent_status":"idle","name":"helper",
   "pane_id":"w1:p1","workspace_id":"w1"},
  {"agent":"codex","agent_status":"working",
   "pane_id":"w2:p2","workspace_id":"w2"}]}}}' > "$dir/snapshot.json"
}
