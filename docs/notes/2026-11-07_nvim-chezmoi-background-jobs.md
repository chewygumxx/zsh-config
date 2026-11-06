---
ctime: 2026-11-07
mtime: 2026-11-07
spdx: GPL-3.0-only
title: Neovim Wrapper Background Chezmoi Jobs
description: >-
  Cause and prevention of stopped background chezmoi jobs launched by the
  Neovim wrapper, with runtime limits and diagnostic locations.
tags:
  - zsh
  - nvim
  - chezmoi
  - debugging
---

<!--
   -
   - ~chewygumxx/zsh-config.git
   - ::: :/docs/notes/2026-11-07_nvim-chezmoi-background-jobs.md
   -
   -->

# Neovim Wrapper Background Chezmoi Jobs

`zsh/wrap/nvim` refreshes a cache of managed paths in the background and
starts background `chezmoi add` and `chezmoi re-add` commands after edits.

The former launch mechanism, `< /dev/null &!`, redirected stdin and disowned
the job but retained its controlling terminal. A command opening `/dev/tty`
could stop the whole background process group with `SIGTTIN`. If chezmoi
held its persistent-state lock, other commands then timed out. Killing the
child left a zombie because its stopped Zsh parent could not reap it.

The wrapper now uses `setsid --fork --wait` to remove the controlling
terminal. Commands needing terminal input fail with a recorded diagnostic.
Automatic jobs require util-linux `setsid` and `flock`, plus GNU `timeout`.
If a helper is missing, the wrapper reports that requirement and still opens
the editor, skipping automatic chezmoi work.

The wrapper checks `timeout`, `gtimeout`, then `gnutimeout` for a GNU
implementation. Ubuntu 26.04 defaults to uutils `timeout` and also installs
GNU as `gnutimeout`. The uutils 0.8.0 implementation used by the CI runner
does not kill the whole process group when escalating to `SIGKILL`, leaving
helpers alive and causing both timeout-cleanup regression tests to fail.
The same fixtures pass with GNU timeout inside that Ubuntu container.
This is tracked in [uutils issue #15768](https://github.com/uutils/coreutils/issues/15768).
If no GNU implementation is available, automatic jobs are skipped with a
diagnostic rather than using timeout behavior that cannot guarantee cleanup.

Each background command has a 60-second execution limit, starting after it
acquires the wrapper's queue lock. Waiting edits retain their full execution
budget. `NVIM_CHEZMOI_TIMEOUT` can override this duration using GNU timeout
syntax, for example `120s`. After the limit, `timeout` sends `SIGTERM`, then
`SIGKILL` five seconds later. A shell supervisor stays alive during that
grace period so the final kill still reaches helpers if chezmoi exits first.
`flock --close` holds the queue lock outside that process group and closes
its descriptor in children. The cache-refresh lock descriptor is also closed
in children, so a background helper cannot retain either wrapper lock after
a successful command exits.

Wrapper commands share a lock so cache reads and source writes do not race
one another. A separate nonblocking lock prevents duplicate cache refreshes.
A failed refresh retains the previous cached paths and removes temporary
files. These locks coordinate this wrapper's jobs; ordinary chezmoi commands
still use chezmoi's own persistent-state lock.

Output and errors go to `$zsh_dirs[cache]/nvim/chezmoi.log`, normally
`$XDG_CACHE_HOME/zsh/nvim/chezmoi.log`. The fallback cache root, where
`zsh_dirs` is unavailable, is `${XDG_CACHE_HOME:-$HOME/.cache}/zsh`.

The regression checks in `tests/wrap.zunit` launch interactive shells through
Zsh's `zpty` module. They exercise all three launch paths with a helper that
tries to read `/dev/tty`, overlapping edits queued beyond one execution
deadline, duplicate refreshes, a command ignoring `SIGTERM`, and a helper
surviving its parent's termination, and helpers left running after a
successful command. Every fixture uses temporary paths and stubs instead of
the user's chezmoi source and database.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown: -->
