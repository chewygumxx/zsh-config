#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/zsh-config.git
# ::: :/util/linters.rc.zsh
#
#
# Plain aliases; no helper is involved. This previously claimed a dependency on
# an `alias_def` function, which does not exist anywhere in the repository.
#

alias lint-json="json-glib-validate"
alias lint-toml="tombi lint"
alias lint-yaml="yamllint"

alias lint-css="stylelint"

# TODO(@chewygumxx): (Priority: Low)
# No JavaScript or TypeScript linter is settled on yet. These were previously
# defined as empty aliases, which is worse than leaving them undefined: alias
# expansion removes the alias word entirely, so `lint-js foo.js` ran `foo.js` as
# the command and reported `command not found: foo.js`. Undefined, the same call
# reports `command not found: lint-js`, which is at least true.
#alias lint-js=""

alias lint-lua="luacheck"
alias lint-py="ruff"

alias lint-sql="sqruff lint"
# See the lint-js note above.
#alias lint-ts=""

alias lint-systemd="systemd-analyze verify"
alias lint-tldr="tldr-lint"
