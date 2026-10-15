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

#
# Write a stand-in for the script `herdr completion zsh` prints.
#
# It carries one argument spec of every shape comp/_herdr rewrites, and three
# it must leave alone: an ID that names no herdr object, and a `target` outside
# the `herdr agent` block, which there names a terminal rather than an agent.
# The specs sit in a function that is never called, so sourcing the script
# runs none of them; only the stand-in _herdr is live, and it reports how it
# was called.
#
# The foot is the dispatch clap appends. Sourced as it stands, it would call
# compdef, which a shell without compinit has no definition of.
#
function stub_herdr_script() {
    emulate -L zsh

    local dir="$1"

    [[ -n "$dir" ]] || return 1

    # The script is zsh source held as data, so every expansion in it is meant
    # to stay literal.
    # shuck: disable=C005
    local -a script=(
        '#compdef herdr'
        ''
        '_herdr() { print -r -- generated "$*"; }'
        ''
        '_herdr_specs() {'
        '_arguments : \'
        "':pane_id:_default' \\"
        "'::pane_id:_default' \\"
        "'--pane[Existing pane]:ID:_default' \\"
        "'--source-pane[]:ID:_default' \\"
        "'--target-pane[]:PANE:_default' \\"
        "':tab_id:_default' \\"
        "'--tab[]:TAB_ID:_default' \\"
        "':workspace_id:_default' \\"
        "'--workspace[]:WORKSPACE_ID:_default' \\"
        "'--source[]:ID:_default' \\"
        "':target:_default' \\"
        '&& ret=0'
        'curcontext="${curcontext%:*:*}:herdr-agent-command-$line[1]:"'
        '_arguments : \'
        "':target:_default' \\"
        "'::target:_default' \\"
        '&& ret=0'
        'curcontext="${curcontext%:*:*}:herdr-terminal-session-command-$line[1]:"'
        '_arguments : \'
        "':target:_default' \\"
        '&& ret=0'
        '}'
        ''
        'if [ "$funcstack[1]" = "_herdr" ]; then'
        '    _herdr "$@"'
        'else'
        '    compdef _herdr herdr'
        'fi'
    )

    print -rl -- $script > "$dir/completion.zsh"
}
