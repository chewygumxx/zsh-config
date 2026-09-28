---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/zsh-config.git
  # ::: :/.github/workflows/CLAUDE.md
  #
  #

ctime: 2026-09-26
title: CLAUDE.md
tags: [llm, claude]
---

# CLAUDE.md

Ensure any workflow within this repository that utilises Node.js employs version
24 or later.

Node 24 bundles npm 11, which is below the npm 12 floor that
`patchedDependencies` in `package.json` requires, so workflows running `npm ci`
must upgrade npm explicitly before installing.
