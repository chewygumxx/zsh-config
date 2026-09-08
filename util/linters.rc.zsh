#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/util/linters.rc.zsh
#
#
# Depends on alias_def function
#

alias lint-json="json-glib-validate"
alias lint-toml="tombi lint"
alias lint-yaml="yamllint"
     
alias lint-css="stylelint"
alias lint-js=""
     
alias lint-lua="luacheck"
alias lint-py="ruff"
     
alias lint-sql="sqruff lint"
alias lint-ts=""
     
alias lint-systemd="systemd-analyze verify"
alias lint-tldr="tldr-lint"



