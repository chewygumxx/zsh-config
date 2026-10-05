---
ctime: 2026-09-28
mtime: 2026-10-05
spdx: GPL-3.0-only
title: Code Review of the Zsh Sources
description: >-
  A full read-through review of the zsh sources, with each finding fixed in its
  own commit.
tags:
  - zsh
  - review
---

<!--
   -
   - ~chewygumxx/zsh-config.git
   - ::: :/docs/code-review.md
   -
   -->

# Code Review of the Zsh Sources

Review date: 2026-09-28. Branch: `claude/code-review`, based on `8278c1b`.

## Scope and method

Every zsh file in the repository was read in full: `.zshenv`, `.zshrc`, and
everything under `env/`, `rc/`, `util/`, `spec/`, `func/`, `wrap/` and
`tests/`. Any finding that depended on how zsh behaves was checked by running
it in `zsh -f` (zsh 5.9) before being reported.

Each finding below was then fixed in its own commit. Wherever the sandbox could
express it, the fix came with a regression test, and each of those tests was
seen to fail against the unfixed code before being trusted green. Every commit
passed the repository's own `pre-commit` hook, which runs `mise run lint` and
`mise run test` over the whole tree.

Line numbers refer to the files as they stood at `8278c1b`.

## Outcome

| Severity                 | Raised | Fixed | Withdrawn |
| ------------------------ | -----: | ----: | --------: |
| Higher impact            |     10 |    10 |         0 |
| Medium                   |      5 |     5 |         0 |
| Low and nits             |     24 |    23 |         1 |
| Pre-existing known skips |      3 |     3 |         0 |
| Test suite               |      3 |     3 |         0 |

The counts follow the sections of this report, which differ slightly from the
original review given in conversation. There, findings 3 and 4 below were one
item about PATH, and the clone routine in `rc/completion.rc.zsh`, folded into
finding 10 here, was listed as a medium finding of its own.

The suite grew from 37 tests, three of them skipped, to 74 tests with none
skipped. `mise run lint` and `mise run test` both pass, the latter with the
plugin cache borrowed through `ZSH_TEST_PLUGIN_DIR` so that `tests/boot.zunit`
runs rather than skips.

## Higher impact

### 1. Cache directories were never recreated

- **Where:** `env/zsh_dirs.env.zsh:63-74`
- **Problem:** A stamp at `~/.local/cache/.zsh_dirs_initialised` stood in for
  the tree it described, but lived outside it. Deleting `~/.local/cache/zsh`
  left the stamp behind, so nothing was recreated, `zsh_dirs_require` failed in
  `rc/completion.rc.zsh`, and every shell started with no completion.
- **Fix:** Each directory is tested on every start and only missing ones are
  made. The stamp is gone.
- **Commit:** `6a7c700`
- **Test:** `tests/env.zunit`, "A deleted cache tree is recreated on the next
  start".

### 2. A forwarded ssh agent was overwritten

- **Where:** `env/ssh.env.zsh:12`
- **Problem:** `SSH_AUTH_SOCK` was exported unconditionally by a file that runs
  for every zsh, replacing the forwarded agent of an `ssh -A` login. With
  `XDG_RUNTIME_DIR` unset it became `/ssh-agent-protonpass.socket`.
- **Fix:** A socket set by ssh inside an SSH session is kept. The runtime
  directory falls back to `/run/user/$UID`.
- **Commit:** `f7f5ffa`
- **Test:** `tests/env.zunit`, "A forwarded agent socket survives an ssh login"
  and "A local shell uses the Proton Pass agent socket".

### 3. PATH grew per nested shell

- **Where:** `env/base.env.zsh:16`
- **Problem:** `path` was not unique, so every nested zsh prepended the same
  three entries again.
- **Fix:** `typeset -gU path`, with `XDG_DATA_HOME` read with a fallback.
- **Commit:** `8acd109`
- **Test:** `tests/env.zunit`, "A nested shell does not grow PATH".

### 4. The luarocks cache replaced PATH wholesale

- **Where:** `util/luarocks.rc.zsh:30`
- **Problem:** The cached output of `luarocks path --bin` contains
  `export PATH='...'` holding the full PATH of whichever shell generated it.
  Every later shell had its PATH replaced with that stale snapshot.
- **Fix:** Only the `LUA_PATH` and `LUA_CPATH` exports are cached. The rock bin
  directories from `--lr-bin` are added only when not already on `path`, so a
  directory such as `/usr/bin` is never moved to the front. The helper
  variables are now function-local rather than global.
- **Commit:** `5bb2e43`
- **Test:** `tests/boot.zunit`, "The luarocks cache leaves the rest of PATH
  alone", driven by a stub `luarocks`.

### 5. `nvim --version` opened a file

- **Where:** `wrap/nvim:22-27`
- **Problem:** A single argument was resolved with `${1:a}` whatever it was.
  `nvim --version` opened `$PWD/--version`, and `cmd | nvim -` opened `$PWD/-`
  instead of reading stdin. Every editor alias inherited this.
- **Fix:** A lone argument beginning with `-` or `+` is passed through as is.
- **Commit:** `236c151`
- **Test:** `tests/wrap.zunit`, "nvim passes a lone option straight through"
  and "nvim reads stdin when given a lone dash".

### 6. `rm` refused but reported success

- **Where:** `wrap/rm:18-28`
- **Problem:** With a trash helper aliased, `rm` printed a hint to stdout and
  returned 0, so `rm file && next` carried on as though the file were gone.
- **Fix:** The hint goes to stderr and the function returns 1.
- **Commit:** `1247fe7`
- **Test:** `tests/wrap.zunit`, the existing refusal test now asserts the
  status.

### 7. `eza` option values became paths

- **Where:** `wrap/eza:72`
- **Problem:** The catch-all option branch took the option alone, so the `2` of
  `lt --level 2` was listed as `$PWD/2`. The wrapper also claimed `-u`, which is
  eza's `--accessed`, and did not count the `l` in a cluster such as `-la`.
- **Fix:** Options taking a value keep it. Short-flag clusters are taken apart,
  counting `l` and honouring `T`, and a value-taking letter ends the cluster.
  The wrapper's own switch is `--unignore` only, and `--` is honoured.
- **Commits:** `0bf0a0b` (tabs to spaces first, so the logic diff stays
  readable), `d3352ef`
- **Test:** `tests/wrap.zunit`, three eza tests.

### 8. The menuselect vi motions were never bound

- **Where:** `rc/completion.rc.zsh:130-136`
- **Problem:** The bindings were queued onto a `bindkey_calls` array that
  nothing in the repository ever read.
- **Fix:** The four `bindkey -M menuselect` calls are made directly.
- **Commit:** `37aad96`
- **Test:** `tests/boot.zunit`, "Menu selection gets vi motions when fzf is
  absent", which skips when fzf is installed, since fzf-tab then owns the menu.

### 9. The OpenRouter key was visible in the process list

- **Where:** `func/openrouter:66-71`
- **Problem:** `-H "Authorization: Bearer $KEY"` placed the key in curl's argv,
  readable by any local user through `/proc/<pid>/cmdline`. A failed `pass-cli`
  was also invisible, because `local x="$(...)"` reports the status of `local`,
  and the log format strings had no newline.
- **Fix:** The header reaches curl as `-H @<(...)`, a file descriptor. The key
  lookup is checked, including for an empty result, and the log lines end in a
  newline.
- **Commit:** `aab62ec`
- **Test:** `tests/func.zunit`, "openrouter never puts the API key in an
  argument" and "openrouter stops when the API key cannot be read".

### 10. Interrupted plugin clones could not be repaired

- **Where:** `rc/plugin.rc.zsh:47`, and `rc/completion.rc.zsh:24-31` and `:109`
- **Problem:** The entry-point check correctly spotted an interrupted clone,
  but `git clone` into the leftover non-empty directory always fails, so the
  plugin reported a failed clone on every start. `rc/completion.rc.zsh` carried
  its own clone routine that still tested only for the directory, then sourced
  fzf-tab unconditionally.
- **Fix:** A shared `func/__plugin_clone` validates the slug, clones into a
  staging directory, and moves it into place only once the entry point is
  present. Both rc files use it; `rc/completion.rc.zsh` autoloads it by path
  because `func/` is not yet on `fpath` there.
- **Commit:** `c172669`
- **Test:** `tests/func.zunit`, three `__plugin_clone` tests, driven by a stub
  `git`.

## Medium

### Generated completions were never loaded

- **Where:** `util/chezmoi.rc.zsh:46` and `:54`
- **Problem:** `_chezmoi` was written to `cache_comp`, which was never on
  `fpath`. The freshness check also compared against `${(%):-%N}` inside an
  anonymous function, which is `(anon)`, a path that never exists, so `-ot` was
  always false.
- **Fix:** `cache_comp` is on `fpath`, and the file path is captured outside
  the function.
- **Commit:** `6ac8aff`
- **Test:** `tests/boot.zunit`, "Generated completions are on fpath".

### `czd` ran a subcommand that does not exist

- **Where:** `util/chezmoi.rc.zsh:44`
- **Fix:** `cz destory` is now `cz destroy`.
- **Commit:** `4aa096a`
- **Test:** `tests/boot.zunit`, "The chezmoi aliases name real subcommands".

### The bat help pager caught human-readable `-h`

- **Where:** `util/bat.rc.zsh:24`
- **Problem:** `df -h`, `du -h`, `free -h` and `sort -h` had their output piped
  through `bat --language=help`.
- **Fix:** A trailing `--help` is always paged. A trailing `-h` is paged unless
  the command, found after any precommand modifier such as `sudo` and through
  any alias, is one where `-h` means something else.
- **Commit:** `b950f46`
- **Test:** `tests/boot.zunit`, "The bat help pager leaves a human-readable -h
  alone".

### `chezmoi help` lost one section and doubled another

- **Where:** `wrap/chezmoi:41` and `:50-52`
- **Problem:** The `printf` arguments sat on a new line without a backslash, so
  the custom section was always empty. The slices `[1,3]` and `[3,-1]` printed
  chezmoi's command list twice.
- **Fix:** The continuation is restored, the tail starts at `[4,-1]`, and two
  `IFS=' '` prefixes that had no effect were replaced by explicit joins.
- **Commit:** `f44d54d`
- **Test:** `tests/wrap.zunit`, "chezmoi help adds its own section exactly
  once".

### Tool paths applied to interactive shells only

- **Where:** `rc/environment.rc.zsh`
- **Problem:** `GNUPGHOME`, `CARGO_HOME`, `GOPATH` and the rest were exported
  only for interactive shells, so scripts and `ssh host cmd` used different
  locations. None had an XDG fallback, and `GOROOT` was hardcoded.
- **Fix:** Moved to `env/tools.env.zsh`, exported for every shell with
  fallbacks and without per-tool `$+commands` checks, which would otherwise
  hash all of PATH in every non-interactive shell. `GOROOT` is no longer set,
  since the go command locates its own root.
- **Commit:** `ef305e0`
- **Test:** `tests/env.zunit`, "A non-interactive shell carries the tool
  relocations".

## Low and nits

- **Missing XDG fallbacks** in `util/nvm.rc.zsh`, `wrap/gtrash:29` and
  `wrap/nvim:172`. The `wrap/cloudflared:22` cache fallback now follows the
  repository's `~/.local/cache` convention. The `env/` cases were fixed with
  findings 2 and 3 and the tool paths. Commits `78f27ce` and `e70a50c`; the
  latter adds `sandbox_zsh_bare` and a test that no path collapses to the root
  when no XDG variable is set.
- **`~sysu` and `~envd` overridden** by `util/systemd.rc.zsh:17-18`, which ran
  last and pointed them at directories that need not exist. Removed there, so
  `rc/directory.rc.zsh` alone defines them. Commit `b8cd88e`, with a test.
- **`_comp_options+=(globdots)` before `compinit`** was discarded, because
  `compinit` assigns the array. Moved after it. Commit `fd05bc1`, with a test.
- **fzf-tab preview glob** read `[0-9a=f]`. Commit `eac7459`.
- **`autoload -Uz` with no names** lists every autoload function on stdout,
  and `(N:t)` also matched subdirectories and, with `globdots`, dotfiles. Now
  collected as `[^.]*(N.:t)` and autoloaded only when non-empty. Commit
  `538f0ab`, with tests that interactive stdout is empty and that every
  function file is autoloaded.
- **Termux named directories** held a trailing slash, so none ever shortened
  `%~`. Commit `c039b21`, with a test.
- **`IFS=" "` prefix in `func/gc`** did nothing, since `"$*"` is expanded with
  the caller's `IFS`. Commit `d0f5917`, with a test.
- **`journal_dir` leaked** from `func/journal`. Commit `33d0d4d`, with a test.
- **`$PAGER` and `$HELPPAGER` not split** in `wrap/gh`, so a pager with
  arguments failed. Commit `64d0daf`, with a test.
- **git complained on stderr** on every `claude` launch outside a repository.
  Commit `335de0d`, with a test.
- **An empty zoxide cache** from a failed `zoxide init` was sourced forever,
  since the check was `-f`. Now `-s`. Commit `795d72f`.
- **`systemd-run` rejected paths** such as `./job`. Commit `4f93349`, with a
  test.
- **`tldr` passed unquoted `$@`** and had no command guard. Commit `6a200de`.
- **`unicode-search-fonts` usage** went to stdout with status 0. Now stderr
  and status 2. Commit `1e0ca6a`, with a test.
- **`func/gcp` comment** named `g --help`. Commit `e2518b3`.
- **`rc/history.rc.zsh`** set `SAVEHIST` above `HISTSIZE`, the reverse of the
  manual's advice, and misdescribed `inc_append_history_time`. Commit
  `b1f3deb`.
- **`rc/ls_colors.rc.zsh` header** pointed at `rc/util/eza.rc.zsh`. Commit
  `7ef9bd2`.
- **Prompt job count** had no closing `%f`. Commit `89a07d6`.
- **Misindented warnings** in `util/chezmoi.rc.zsh` and `util/eza.rc.zsh`.
  Commit `5e29810`.
- **Tab indentation** in `wrap/eza` and `wrap/cloudflared`. Commit `0bf0a0b`.
- **`sudo pacman` became `sudo yay`**, which yay refuses, because
  `alias sudo="sudo "` expanded the `pacman=yay` alias. Replaced by
  `wrap/pacman`, a function, which sudo never expands. Commit `434660e`, with a
  test.
- **`globdots` makes `rm -rf *` include `.git`.** A deliberate choice, so it is
  documented where it is set rather than changed. Commit `1db801e`.
- **Variable leak in `util/luarocks.rc.zsh`** fixed with finding 4.

### Withdrawn

- **`func/__slugify` relying on the caller's `extended_glob`.** Wrong: the
  function already sets `emulate -L zsh` and `extended_glob` on lines 10 and
  11, which the original read skipped. The attempted fix was dropped before it
  was pushed. The test written for it was kept, since it pins the behaviour.
  Commit `ad4e853`.

## Pre-existing known skips

These three defects were recorded as `skip`ped tests before this review. Each
skip was removed along with its fix, as `.claude/CLAUDE.md` asks.

- **`wrap/jq`** tested `(($+@[--indent]))`, which raised `bad math expression`
  on every call and was never true. It now checks for `--indent`, `--tab`, `-c`
  and `--compact-output`. Commit `85716eb`.
- **`wrap/chezmoi`** assigned `__this__file` and printed `__this_file`, with no
  trailing newline. Commit `9d86981`.
- **`wrap/sv`** did the reverse, and its message read "This is function is".
  Commit `561fe2a`.

## Test suite

- **"Every enabled spec is loaded"** checked three hand-written function names.
  `rc/plugin.rc.zsh` now records `zsh_plugins_loaded`, and the test compares it
  with the enabled specs read from `spec/`. Seen to fail when a plugin is kept
  from loading. Commit `7a429aa`.
- **The `rm` refusal test** did not assert the exit status. Fixed with
  finding 6.
- **Regression tests for findings 1, 5 and 7** were added with their fixes.
  `tests/env.zunit` is new; it starts only non-interactive shells, so unlike
  `tests/boot.zunit` it needs no plugin clones and always runs.

## Tooling discoveries

These cost time during the work and are now recorded in `.claude/CLAUDE.md`
(commit `008c02d`):

- **`shuck format` deletes comments above an anonymous function.** A comment
  block directly above `() {` is removed; at the top of a file that includes
  the header block. Comments go inside the function body instead.
- **A failing command outside `run` fails a zunit test with no message.**
  Capture a deliberately failing call through `run`, or add `|| true`.

## Verification

- `mise run lint`: pass.
- `mise run test`: 74 of 74 pass, none skipped, with `ZSH_TEST_PLUGIN_DIR`
  pointing at fresh clones of every plugin in `spec/` and
  `rc/completion.rc.zsh`.
- Every commit on the branch passed the `pre-commit` hook, which runs both.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
