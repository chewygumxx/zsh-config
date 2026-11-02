---
ctime: 2026-11-03
mtime: 2026-11-03
spdx: GPL-3.0-only
title: Runtime Directory Separation Plan
description: >-
  Implementation plan for moving the effective Zsh configuration beneath zsh/,
  splitting the test helpers' repository and runtime roots, and adding the
  deployment-shaped fixtures the specification requires.
tags:
  - zsh
  - architecture
  - plan
---

<!--
   -
   - ~chewygumxx/zsh-config.git
   - ::: :/docs/plan/2026-11-03_runtime-directory-separation.md
   -
   -->

# Runtime Directory Separation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every runtime file beneath `zsh/` so that directory alone is a
complete `ZDOTDIR`, with tests and tooling adapted and the new properties
pinned by fixtures.

**Architecture:** One behaviour-preserving relocation commit, preceded by a
pure refactor that gives the test helpers two roots (`ZSH_REPO_ROOT`,
`ZSH_CONFIG_ROOT`) while both still hold the same value. New fixtures then
start the runtime from a copied, tracked-only installation, from a hostile
directory name, cold, and through a home startup link. Editor tooling and
documentation follow. The live cutover is a separate installation task.

**Tech Stack:** zsh, zunit 0.8.2 (`mise run test`), shuck, mise tasks,
GitHub Actions, Neovim (`.nvim.lua`).

**Spec:**
[docs/spec/2026-11-03_runtime-directory-separation.md](../spec/2026-11-03_runtime-directory-separation.md)

## Global Constraints

- No em dashes anywhere in the repository, including comments, tests and commit
  messages.
- Commit messages: Conventional Commits, header at most 50 characters, subject
  in sentence case, body lines at most 72. Scopes only `env`, `rc`, `util`,
  `func`, `wrap`, `spec`, `comp`, `claude`; root-level and cross-cutting
  changes take a bare type.
- Every commit must pass `.husky/pre-commit` (`mise run lint` then
  `mise run test`). Never bypass it with `--no-verify`.
- Source paths in `zsh_dirs` keep deriving from `ZDOTDIR`; runtime code must
  not append a `zsh` component, search for the Git root, or source from a
  parent directory.
- The XDG defaults and the fallback configuration path remain unchanged.
- No root startup shim or compatibility loader is introduced.
- No build step, no new installation tool, no change to plugin management or
  load order.
- Test setup never exports into later tests; pass values through
  `SANDBOX_ENV` or `env -i`.
- Every new assertion must be observed failing against a deliberately broken
  condition before it is trusted green (`AGENTS.md`, "Verifying changes").
- Never run the suite in the live clone (`~/.config/zsh`).
- Do not `git push local main` at any point in this plan. The live cutover is
  a separate installation task.
- Changes reach `main` through a pull request; push and open it only with the
  user's go-ahead.

## Review Focus

1. **Pushing the merged result to `local`.** The relocation commit deletes
   `.zshenv` and `.zshrc` from the root of the live clone, which is today's
   `ZDOTDIR`, so every new shell would start unconfigured. A reasonable person
   following the existing "merge, pull, push local" routine expects a working
   shell. No suite test can pin this; Task 6 puts an explicit stop in
   `AGENTS.md` where that routine is described.
2. **A machine whose global zshenv assigns `ZDOTDIR`.** This machine's
   `/etc/zsh/zshenv` sets it even under `zsh -f`, so zsh never reads
   `~/.zshenv` and a portable-startup fixture would pass without exercising
   discovery. Task 4 detects this with `sandbox_global_sets_zdotdir` and skips
   with a reason; Task 7 confirms on CI, where Ubuntu's global file does not
   assign it, that the fixture really ran.
3. **A glob that silently stops matching after the move.** Every pattern in
   `lint:syntax` and `tests/header.zunit` carries `(N)`, so a stale path
   drops a whole directory from the check with the gate still green. Task 2
   adds coverage checks against `git ls-files` to both.
4. **shuck reading moved files as sh.** An unmapped zsh file is formatted as
   sh, and `shuck format` then rewrites `(($+functions[x]))` into an
   expression with the opposite meaning. Task 2 includes a break-and-observe
   step that proves `zsh/.zshenv` and `zsh/func/*` are discovered and mapped.
5. **Untracked or generated files riding into a fixture.** A generated
   `env/chezmoi.env.zsh`, or the stray `util/.remember/` that `git mv` carries
   along, must not reach a deployment-shaped install. Task 3's installer
   copies only `git ls-files` output, and Task 2's layout test fails loudly if
   the checkout holds a generated environment file.

---

## File Structure

| Path                                                   | Change                                                                 |
| ------------------------------------------------------ | ---------------------------------------------------------------------- |
| `zsh/` (new)                                           | Receives `.zshenv`, `.zshrc`, `env/ rc/ util/ func/ wrap/ comp/ spec/` |
| `tests/_support/sandbox.zsh`                           | Two roots; `sandbox_install_runtime`, `sandbox_zsh_home`, global probe |
| `tests/_support/autoload.zsh`                          | Two roots                                                              |
| `tests/layout.zunit` (new)                             | Root contract, relocation (A1), ignore and generated-file guards (A8)  |
| `tests/header.zunit`                                   | Repo-relative paths; tracked-file coverage check                       |
| `tests/boot.zunit`                                     | Hostile directory (A3), installed copy (A4), portable interactive (A6) |
| `tests/env.zunit`                                      | Cold stdout (A5), portable non-interactive (A6)                        |
| `.mise.toml`                                           | `lint:syntax` paths and coverage check                                 |
| `.shuck.toml`                                          | `per-file-shell` keys                                                  |
| `.gitignore`                                           | `/zsh/env/chezmoi.env.zsh`                                             |
| `.github/workflows/lint.yaml`                          | Plugin cache key inputs                                                |
| `.nvim.lua`                                            | Classify files under `zsh/`                                            |
| `.worktreeinclude`                                     | `env*` becomes `.env*`                                                 |
| `AGENTS.md`                                            | Layout, installation, live-push stop, tests                            |
| `docs/spec/2026-11-03_runtime-directory-separation.md` | Status row                                                             |

Unchanged on purpose: `.prettierignore` and `.gitattributes` (no pattern
changes meaning), `rc/directory.rc.zsh` (`~zsh` keeps preferring
`~/dev/zsh-config`, the repository root, which is navigation only),
nvim-config's `lua/util/shebang.lua` (its `~/dev/zsh-config` entry is a prefix
match and still covers `zsh/`), and
`docs/2026-09-28_code-review-zsh-sources.md` (a dated record).

---

### Task 1: Separate the repository and runtime roots

A pure refactor. Both roots hold the repository root until Task 2, so every
existing test keeps passing; the point is that each consumer is now named for
the root it means.

**Files:**

- Create: `tests/layout.zunit`
- Modify: `tests/_support/sandbox.zsh:26-28` and `:155-168`
- Modify: `tests/_support/autoload.zsh:22`
- Modify: `tests/header.zunit:28-46`, `:67-74`, `:93`, `:111-114`, `:129`

**Interfaces:**

- Produces: globals `ZSH_REPO_ROOT` (repository root, from the helper's own
  path) and `ZSH_CONFIG_ROOT` (runtime root), set identically by
  `tests/_support/sandbox.zsh` and `tests/_support/autoload.zsh`.

- [ ] **Step 1: Prepare the workspace**

Work on branch `refactor/runtime-directory`, which already carries this plan.
Run `git status --short` and confirm the tree is clean.

Ask the user whether to delete the stray, ignored `util/.remember/` (Remember
plugin state from 2026-09-29). If they agree, run
`rm -rf -- util/.remember`. If not, leave it. `git mv` in Task 2 carries it
into `zsh/util/.remember/`, where no loader glob matches it.

- [ ] **Step 2: Write the failing test**

Create `tests/layout.zunit`:

```zsh
#!/usr/bin/env zunit
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/tests/layout.zunit
#
#

#
# The repository layout contract: where the runtime lives relative to the
# repository, and which roots the test helpers derive from their own location.
#

@setup {
    load _support/sandbox
}

@test 'Both helpers derive the same roots from any directory' {
    # Each helper is sourced in a fresh shell started from /, so a root
    # derived from $PWD rather than from the helper's own path would show up
    # here as a wrong value rather than passing by coincidence.
    local helper
    local -a seen=()

    for helper in autoload sandbox; do
        seen+=("$(cd / && zsh -fc '
            source "$1"
            print -r -- "$ZSH_REPO_ROOT|$ZSH_CONFIG_ROOT"
        ' zsh "$ZSH_REPO_ROOT/tests/_support/$helper.zsh")")
    done

    assert "$ZSH_REPO_ROOT/.mise.toml" is_file
    assert "$seen[1]" same_as "$ZSH_REPO_ROOT|$ZSH_REPO_ROOT"
    assert "$seen[2]" same_as "$seen[1]"
}
```

- [ ] **Step 3: Run it to verify it fails**

Run: `mise x -- zunit run --tap tests/layout.zunit`

Expected: FAIL. `ZSH_REPO_ROOT` is unset, so `is_file` tests `/.mise.toml`.

- [ ] **Step 4: Define both roots in the helpers**

In `tests/_support/sandbox.zsh`, replace lines 26-28:

```zsh
# Derived from this file rather than from $PWD, so the suite does not depend on
# the directory zunit was invoked from.
ZSH_CONFIG_ROOT="${${(%):-%N}:A:h:h:h}"
```

with:

```zsh
# Derived from this file rather than from $PWD, so the suite does not depend on
# the directory zunit was invoked from. Two roots, because they answer
# different questions: ZSH_REPO_ROOT is where the project files, tests and
# .mise.toml live, and ZSH_CONFIG_ROOT is the runtime that ZDOTDIR names.
# tests/_support/autoload.zsh derives the same pair, and tests/layout.zunit
# holds the two to agreement.
ZSH_REPO_ROOT="${${(%):-%N}:A:h:h:h}"
ZSH_CONFIG_ROOT="$ZSH_REPO_ROOT"
```

In `tests/_support/autoload.zsh`, replace line 22:

```zsh
ZSH_CONFIG_ROOT="${${(%):-%N}:A:h:h:h}"
```

with:

```zsh
# The same pair tests/_support/sandbox.zsh derives; see the note there.
ZSH_REPO_ROOT="${${(%):-%N}:A:h:h:h}"
ZSH_CONFIG_ROOT="$ZSH_REPO_ROOT"
```

- [ ] **Step 5: Point repository-side consumers at `ZSH_REPO_ROOT`**

In `tests/_support/sandbox.zsh`, in `sandbox_zsh`, change
`MISE_TRUSTED_CONFIG_PATHS="$ZSH_CONFIG_ROOT" \` to
`MISE_TRUSTED_CONFIG_PATHS="$ZSH_REPO_ROOT" \`. In the comment above it,
change "this checkout's .mise.toml" to "the repository's .mise.toml".

In `tests/header.zunit`:

- Line 42: `"$ZSH_CONFIG_ROOT"/tests/_support/*.zsh(N)` becomes
  `"$ZSH_REPO_ROOT"/tests/_support/*.zsh(N)`.
- Line 45: `TEST_FILES=("$ZSH_CONFIG_ROOT"/tests/*.zunit(N))` becomes
  `TEST_FILES=("$ZSH_REPO_ROOT"/tests/*.zunit(N))`.
- Every `${file#$ZSH_CONFIG_ROOT/}` (lines 69, 74, 93, 111, 114, 129) becomes
  `${file#$ZSH_REPO_ROOT/}`. Headers name repository-relative paths, so after
  Task 2 this is what yields `zsh/rc/completion.rc.zsh`.
- Line 67, `"$ZSH_CONFIG_ROOT"/comp/*`, stays: it identifies runtime files.

Check nothing was missed:

Run: `grep -n 'ZSH_CONFIG_ROOT' tests/header.zunit`

Expected: only lines 33-41 (the runtime globs) and line 67.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `mise run test`

Expected: PASS, 113 tests (112 plus the new one), the same skips as before.

- [ ] **Step 7: Watch the agreement assertion fail**

Stage the work so far with `git add tests`, so the experiment can be undone
from the index. Then change `autoload.zsh`'s new `ZSH_REPO_ROOT` line to
`ZSH_REPO_ROOT="${PWD:A}"`, run
`mise x -- zunit run --tap tests/layout.zunit`, and confirm
`Both helpers derive the same roots from any directory` fails with `/|/`.
Undo it with `git restore tests/_support/autoload.zsh`.

- [ ] **Step 8: Commit**

```bash
git add tests/layout.zunit tests/_support/sandbox.zsh tests/_support/autoload.zsh tests/header.zunit
git commit -m "test: Separate the repository and runtime roots"
```

---

### Task 2: Move the runtime beneath `zsh/`

The single behaviour-preserving relocation. It has to be one commit, because
the pre-commit hook runs the whole gate and none of these edits passes
without the others.

**Files:**

- Move: `.zshenv .zshrc env/ rc/ util/ func/ wrap/ comp/ spec/` to `zsh/`
- Modify: the `# ::: :/` header line of every moved file
- Modify: `tests/_support/sandbox.zsh`, `tests/_support/autoload.zsh` (root)
- Modify: `tests/layout.zunit`, `tests/header.zunit`
- Modify: `.mise.toml` (`lint:syntax`), `.shuck.toml`, `.gitignore`,
  `.github/workflows/lint.yaml`

**Interfaces:**

- Consumes: `ZSH_REPO_ROOT`, `ZSH_CONFIG_ROOT` from Task 1.
- Produces: `ZSH_CONFIG_ROOT="$ZSH_REPO_ROOT/zsh"`. The runtime tree at
  `zsh/`, with headers reading `# ::: :/zsh/<path>`.

- [ ] **Step 1: Write the failing tests**

In `tests/layout.zunit`, change the expectation in
`Both helpers derive the same roots from any directory`:

```zsh
    assert "$seen[1]" same_as "$ZSH_REPO_ROOT|$ZSH_REPO_ROOT/zsh"
```

Append to `tests/layout.zunit`:

```zsh
@test 'The runtime lives beneath zsh/ and nowhere else' {
    # Spec criterion A1. Checked on disk and in the index alike: a file left
    # behind at the root, tracked or not, is a second configuration tree that
    # a stray ZDOTDIR could still select.
    local -a names=(.zshenv .zshrc env rc util func wrap comp spec)
    local -a moved=("$ZSH_CONFIG_ROOT"/${^names}(N))
    local -a strays=("$ZSH_REPO_ROOT"/${^names}(N))
    local -a tracked=(
        ${(0)"$(git -C "$ZSH_REPO_ROOT" ls-files -z -- $names)"}
    )

    if (( ${#strays} )); then
        fail "Left at the root: ${(j:, :)${strays:t}}"
    fi

    assert ${#moved} equals ${#names}
    assert ${#strays} equals 0
    assert ${#tracked} equals 0
}

@test 'The generated chezmoi environment is ignored at its new path' {
    # Spec criterion A8. chezmoi-environment in the dotfiles repository writes
    # this file into the live clone with machine-specific paths, so it has to
    # stay untracked wherever the runtime moves.
    run git -C "$ZSH_REPO_ROOT" check-ignore -q -- zsh/env/chezmoi.env.zsh

    assert $state equals 0
}

@test 'The checkout holds no generated chezmoi environment' {
    # The sandbox links this checkout's runtime, so a generated file here
    # would load the real machine's paths into every test shell. It only ever
    # exists in the live clone, which is why the suite must never run there.
    local -a generated=("$ZSH_CONFIG_ROOT"/env/chezmoi.env.zsh(N))

    if (( ${#generated} )); then
        fail 'env/chezmoi.env.zsh is present; is this the live clone?'
    fi

    assert ${#generated} equals 0
}
```

In `tests/header.zunit`, add after `The file list is not empty`:

```zsh
@test 'Every tracked shell file is checked' {
    # Guards the globs in @setup. Each carries (N), so one that stops
    # matching, as a stale path would after a move, drops its whole directory
    # from every test in this file without a word. comp/.keep is the one
    # tracked file there that is not shell.
    local -a tracked unchecked

    tracked=(${(0)"$(git -C "$ZSH_REPO_ROOT" ls-files -z -- zsh tests/_support)"})
    tracked=("$ZSH_REPO_ROOT"/${^tracked:#*/.keep})
    unchecked=(${tracked:|SHELL_FILES})

    if (( ${#unchecked} )); then
        fail "Not checked: ${(j:, :)${unchecked#$ZSH_REPO_ROOT/}}"
    fi

    assert ${#tracked} is_greater_than 1
    assert ${#unchecked} equals 0
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `mise x -- zunit run --tap tests/layout.zunit tests/header.zunit`

Expected: FAIL on the root agreement (`|<root>` rather than `|<root>/zsh`), on
`The runtime lives beneath zsh/` (nine strays), and on `check-ignore` (exit 1,
the rule still reads `/env/chezmoi.env.zsh`). `Every tracked shell file is
checked` passes at this point, because nothing is tracked under `zsh/` yet;
Step 9 is where it is seen failing.

- [ ] **Step 3: Move the files**

```bash
mkdir zsh
git mv .zshenv .zshrc env rc util func wrap comp spec zsh/
git status --short | grep -vc '^R'
```

Expected: `0` from the last command, meaning every change is a rename, and
`git ls-files zsh | wc -l` prints `73`.

- [ ] **Step 4: Rewrite the moved headers**

```bash
git ls-files -z -- zsh | xargs -0 sed -i 's|^# ::: :/|# ::: :/zsh/|'
git grep -c '^# ::: :/zsh/' -- zsh | wc -l
git grep -n '^# ::: :/' -- zsh | grep -v ':/zsh/'
```

Expected: `72` (every file but `comp/.keep`, which has no header), and no
output from the last command.

- [ ] **Step 5: Point the runtime root at `zsh/`**

In both helpers, change `ZSH_CONFIG_ROOT="$ZSH_REPO_ROOT"` to:

```zsh
ZSH_CONFIG_ROOT="$ZSH_REPO_ROOT/zsh"
```

In `tests/_support/sandbox.zsh`, update the `sandbox_create` comment above the
`ln -sfn` line to read:

```zsh
    # zsh finds .zshenv and .zshrc through ZDOTDIR, and env/zsh_dirs.env.zsh
    # derives every source directory from it, so this symlink is what puts this
    # checkout's runtime, its zsh/ directory, under test rather than the live
    # one. Never the repository root: that is not a configuration.
```

`sandbox_copy_config`, `tests/comp.zunit`'s `touch -r` lines and the runtime
globs in `tests/header.zunit` already read `ZSH_CONFIG_ROOT` and need no edit.

- [ ] **Step 6: Adapt the tooling paths**

`.gitignore`: replace `/env/chezmoi.env.zsh` with `/zsh/env/chezmoi.env.zsh`.

`.shuck.toml`, `[per-file-shell]`: replace the nine runtime keys with:

```toml
"zsh/.zshenv" = "zsh"
"zsh/.zshrc" = "zsh"
"zsh/func/*" = "zsh"
"zsh/wrap/*" = "zsh"
"zsh/comp/*" = "zsh"
"zsh/util/*" = "zsh"
"zsh/spec/*" = "zsh"
"zsh/rc/*" = "zsh"
"zsh/env/*" = "zsh"
```

`.github/workflows/lint.yaml`:

- `key: zsh-plugins-${{ hashFiles('spec/*.spec.zsh', 'rc/completion.rc.zsh') }}`
  becomes
  `key: zsh-plugins-${{ hashFiles('zsh/spec/*.spec.zsh', 'zsh/rc/completion.rc.zsh') }}`.
- In the comment above `Clone plugins`, `rc/completion.rc.zsh` becomes
  `zsh/rc/completion.rc.zsh` and `spec/` becomes `zsh/spec/`.
- The slug list is unchanged: the provisioned plugin set stays the same.

`.mise.toml`, `[tasks."lint:syntax"]`: replace the `files=( ... )` block and
add the coverage check directly after it, so the body reads:

```zsh
    local -a files
    files=(
        zsh/.zshenv
        zsh/.zshrc
        zsh/env/*.env.zsh
        zsh/rc/*.rc.zsh
        zsh/util/*.rc.zsh
        zsh/spec/*.spec.zsh
        zsh/comp/_*(.)
        zsh/func/*(.)
        zsh/wrap/*(.)
        tests/_support/*.zsh
    )

    # null_glob lets a pattern that matches nothing drop out in silence, which
    # would leave a whole directory unparsed with this task still green. So
    # every tracked shell file has to be among those listed. comp/.keep is the
    # one tracked file there that is not shell.
    local -a tracked unparsed
    tracked=(${(0)"$(git ls-files -z -- zsh tests/_support)"})
    tracked=(${tracked:#*/.keep})
    unparsed=(${tracked:|files})

    if (( ${#unparsed} )); then
        print -u2 -- "lint:syntax: [ERROR] Not parsed: ${(j:, :)unparsed}"
        return 1
    fi
```

Leave the existing comment about the `.zunit` carve-out and the parse loop
below it as they are.

- [ ] **Step 7: Run the gates**

Run: `mise run lint && mise run test`

Expected: both PASS. 117 tests (113 plus the four new ones), same skips.

- [ ] **Step 8: Prove shuck discovers and maps the moved files**

This step changes nothing permanent; it shows that Review Focus item 4 holds.

```bash
printf '%s\n' 'if true; then' $'\t:' 'fi' >> zsh/.zshenv
shuck format --check --no-cache; echo "exit $?"
git restore zsh/.zshenv
printf '%s\n' '(($+functions[mkcd])) && :' >> zsh/func/mkcd
shuck format --check --no-cache; echo "exit $?"
git restore zsh/func/mkcd
```

Expected: the first check exits non-zero and names `zsh/.zshenv`, which proves
the dotfile is discovered. The second exits `0`, which proves `zsh/func/*` is
formatted as zsh: read as sh, shuck would rewrite the arithmetic. If either
expectation fails, fix `.shuck.toml` before going on.

- [ ] **Step 9: Watch the coverage checks fail**

Delete the `zsh/env/*.env.zsh` line from `lint:syntax` in `.mise.toml`, and
the `"$ZSH_CONFIG_ROOT"/env/*.env.zsh(N)` line from `tests/header.zunit`'s
`@setup`. Then:

Run: `mise run lint:syntax; mise x -- zunit run --tap tests/header.zunit`

Expected: `lint:syntax: [ERROR] Not parsed: zsh/env/base.env.zsh, ...`, and
`Every tracked shell file is checked` failing with the same eight files.
Restore both lines and re-run to see them pass.

Then create `zsh/env/chezmoi.env.zsh` (`: > zsh/env/chezmoi.env.zsh`), run
`mise x -- zunit run --tap tests/layout.zunit`, confirm `The checkout holds no generated
chezmoi environment` fails, and remove the file.

- [ ] **Step 10: Commit**

```bash
git add -A zsh tests .mise.toml .shuck.toml .gitignore .github/workflows/lint.yaml
git status --short
git commit -m "refactor: Move the runtime beneath zsh/" -m "Everything ZDOTDIR names now lives in zsh/, so that directory alone is
a complete configuration and the repository root holds only project
files. Headers, helper roots, syntax and format globs, the ignore rule
for the generated chezmoi environment and the CI plugin cache key move
with it; load order and runtime behaviour are unchanged.

lint:syntax and tests/header.zunit now also fail when a tracked shell
file escapes their globs, since every pattern there carries (N)."
```

Expected `git status --short` before the commit: only `R` renames under
`zsh/` and `M` for the listed files, with nothing untracked.

---

### Task 3: Start the relocated runtime from elsewhere

Spec criteria A3 and A4. Both tests start interactive shells, so they belong
in `tests/boot.zunit`, behind its plugin-cache guard.

**Files:**

- Modify: `tests/_support/sandbox.zsh` (add `sandbox_install_runtime`)
- Modify: `tests/boot.zunit` (two tests, appended)

**Interfaces:**

- Consumes: `ZSH_REPO_ROOT`, `ZSH_CONFIG_ROOT`, `sandbox_create`,
  `sandbox_copy_config ROOT NAME`, `sandbox_warm ROOT`, `sandbox_zsh ROOT ...`,
  `sandbox_zsh_stdout`, `sandbox_zsh_stderr`, `sandbox_destroy ROOT`.
- Produces: `sandbox_install_runtime ROOT`. It copies tracked `zsh/` files
  into `ROOT/.local/share/zsh-config/`, repoints `ROOT/.config/zsh` at that
  copy's `zsh/` child, prints the live checkout path, and returns 1 on
  failure. Task 4 uses it too.

- [ ] **Step 1: Write the failing tests**

Append to `tests/boot.zunit`:

```zsh
@test 'A runtime under a hostile directory name loads each module once' {
    # Spec criterion A3. Spaces and every loader keyword in one name. The
    # .zshrc reorder patterns are anchored to the final path component;
    # matched as bare substrings they would catch every file here and source
    # each more than once, and an unquoted expansion would split the path.
    local conf
    conf="$(sandbox_copy_config "$SANDBOX" 'a completion function ls_colors dir')"

    print -r -- 'print -u2 PROBE-RC' > "$conf/rc/probe.rc.zsh"
    print -r -- 'print -u2 PROBE-UTIL' > "$conf/util/probe.rc.zsh"

    # Appended after the defaults, so this ZDOTDIR wins.
    local -a SANDBOX_ENV=(ZDOTDIR="$conf")

    run sandbox_zsh "$SANDBOX" -i -c '
        print -r -- "rc:$zsh_dirs[rc]"
        print -r -- "empty:${#${(M)fpath:#}}"
    '

    local -a rc_hits=(${(M)lines:#PROBE-RC})
    local -a util_hits=(${(M)lines:#PROBE-UTIL})

    assert ${#rc_hits} equals 1
    assert ${#util_hits} equals 1
    assert "${(M)lines:#rc:*}" same_as "rc:$conf/rc"
    assert "${(M)lines:#empty:*}" same_as 'empty:0'
}

@test 'An installed copy of the tracked runtime starts on its own' {
    # Spec criterion A4, and the startup half of A9. Shaped like the live
    # installation: tracked files only, copied rather than linked, reached
    # through the configuration path. Repository-local tool directories are
    # dropped from PATH, so a startup that quietly needed Bun or the test
    # binaries would show here. Every probe line has to name the copy, so a
    # shell that started cleanly but loaded nothing cannot pass.
    local root live
    root="$(sandbox_create)"
    live="$(sandbox_install_runtime "$root")"

    local PATH="${(j.:.)${path:#$ZSH_REPO_ROOT/*}}"
    local -a SANDBOX_ENV=(ZSH_TEST_REPO_ROOT="$ZSH_REPO_ROOT")

    sandbox_warm "$root"

    local diagnostics probe
    diagnostics="$(sandbox_zsh_stderr "$root" -i -c exit)"
    probe="$(sandbox_zsh_stdout "$root" -i -c '
        autoload +X mkcd
        print -r -- "conf:${zsh_dirs[conf]:A}"
        print -r -- "func:${functions_source[mkcd]:A}"
        print -r -- "complete:$+functions[_main_complete]"
        print -r -- "plugins:${#zsh_plugins_loaded}"
        local entry
        for entry in $fpath ${(v)zsh_dirs}; do
            [[ "${entry:A}/" == "$ZSH_TEST_REPO_ROOT"/* ]] &&
                print -r -- "leak:$entry"
        done
        true
    ')"

    local -a links=("$live"/**/*(N@D))
    local -a generated=("$live"/zsh/env/chezmoi.env.zsh(N))
    local expected="${live:A}"

    sandbox_destroy "$root"

    local -a lines=("${(@f)probe}")
    local -a leaks=(${(M)lines:#leak:*})

    assert "$diagnostics" is_empty
    assert "$lines[1]" same_as "conf:$expected/zsh"
    assert "$lines[2]" same_as "func:$expected/zsh/func/mkcd"
    assert "$lines[3]" same_as 'complete:1'
    assert "$lines[4]" different_to 'plugins:0'
    assert "${(j: :)leaks}" is_empty
    assert ${#links} equals 0
    assert ${#generated} equals 0
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `mise x -- zunit run --tap tests/boot.zunit`

Expected: the hostile-name test PASSES already, since the anchors exist; it
is pinned by Step 5's break. The installed-copy test FAILS with
`command not found: sandbox_install_runtime`.

- [ ] **Step 3: Add the installer**

Append to `tests/_support/sandbox.zsh`:

```zsh
#
# Install the tracked runtime into a sandbox the way the live installation is
# laid out, and print the live checkout's path.
#
# Only the files git tracks beneath zsh/ are copied, read from the working tree
# so uncommitted edits are what get tested. A generated env/chezmoi.env.zsh, or
# any other untracked file, therefore never reaches the copy, and nothing in it
# links back to this checkout. The configuration path is then repointed at the
# copy's zsh/ child, replacing the link sandbox_create made, so ZDOTDIR is
# reached through a symlink exactly as on the live machine.
#
function sandbox_install_runtime() {
    emulate -L zsh

    local root="$1"

    [[ -n "$root" && -d "$root" ]] || return 1

    local live="$root/.local/share/zsh-config"
    local -a files
    files=(${(0)"$(git -C "$ZSH_REPO_ROOT" ls-files -z -- zsh)"})

    # An empty list would install nothing and leave the old link in place,
    # and every assertion would then be about the checkout instead.
    ((${#files})) || return 1

    local file
    for file in $files; do
        mkdir -p -m 0755 -- "$live/${file:h}" || return 1
        cp -- "$ZSH_REPO_ROOT/$file" "$live/$file" || return 1
    done

    # -n replaces the existing link rather than descending into its target.
    ln -sfn -- "$live/zsh" "$root/.config/zsh" || return 1

    print -r -- "$live"
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mise run test`

Expected: PASS, 119 tests. If the installed-copy test hits zunit's 30 second
`time_limit`, combine the stderr and stdout starts into one `run` and split
the streams with `sandbox_zsh_stderr` alone, rather than raising the limit.

- [ ] **Step 5: Watch both fail**

1. In `zsh/.zshrc`, temporarily change `${(M)zshrcs:#*/completion.rc.zsh}`
   to `${(M)zshrcs:#*completion*}`. Run `mise x -- zunit run --tap tests/boot.zunit`.
   Expected: the hostile-name test fails with `rc_hits` at 2, because the
   directory name now puts every file in the completion group too. Restore
   with `git restore zsh/.zshrc`.
2. In `sandbox_install_runtime`, temporarily replace the `cp --` line with
   `ln -s -- "$ZSH_REPO_ROOT/$file" "$live/$file" || return 1`. Expected: the
   installed-copy test fails on `func:` (it resolves into the checkout) and
   on `links`. Undo the edit.

- [ ] **Step 6: Commit**

```bash
git add tests/_support/sandbox.zsh tests/boot.zunit
git commit -m "test: Start an installed copy of the runtime"
```

---

### Task 4: Cover cold and portable startup

Spec criteria A5 (cold non-interactive stdout) and A6 (portable startup with
no `ZDOTDIR` and no XDG variables). The no-XDG half of A6 already exists as
`No path collapses to the root when XDG variables are unset` in
`tests/env.zunit`.

**Files:**

- Modify: `tests/_support/sandbox.zsh` (add `sandbox_zsh_home`,
  `sandbox_global_sets_zdotdir`)
- Modify: `tests/env.zunit` (two tests), `tests/boot.zunit` (one test)

**Interfaces:**

- Consumes: `sandbox_create`, `sandbox_install_runtime ROOT` (Task 3),
  `sandbox_zsh_stdout`, `sandbox_destroy`.
- Produces: `sandbox_zsh_home ROOT ARGS...`, which runs zsh with only `HOME`,
  `PATH`, `TERM`, `SHELL` and `MISE_TRUSTED_CONFIG_PATHS`. Also
  `sandbox_global_sets_zdotdir ROOT`, which returns 0 when the machine's
  global zshenv assigns `ZDOTDIR` itself.

- [ ] **Step 1: Write the failing tests**

Append to `tests/env.zunit`:

```zsh
@test 'A cold non-interactive start writes no byte to stdout' {
    # Spec criterion A5. A fresh sandbox, never warmed, so env/zsh_dirs.env.zsh
    # takes its directory-creating branch. That branch must report on stderr
    # alone; counted in bytes, as boot.zunit does for warm starts.
    local root
    root="$(sandbox_create)"

    local -i bytes
    bytes=$(sandbox_zsh_stdout "$root" -c exit | wc -c)

    sandbox_destroy "$root"

    assert $bytes equals 0
}

@test 'A home startup link finds the installed runtime' {
    # Spec criterion A6. With no ZDOTDIR anywhere, zsh reads ~/.zshenv, here
    # a link into the installed runtime, and the runtime finds itself through
    # its XDG fallback. Where the global zshenv assigns ZDOTDIR first, as this
    # machine's does, zsh never reads ~/.zshenv at all, so the test would
    # pass without exercising discovery; it skips there instead. CI runs it.
    sandbox_global_sets_zdotdir "$SANDBOX" &&
        skip 'The global zshenv assigns ZDOTDIR, so ~/.zshenv is never read'

    local root
    root="$(sandbox_create)"
    sandbox_install_runtime "$root" > /dev/null
    ln -s -- "$root/.config/zsh/.zshenv" "$root/.zshenv"

    sandbox_zsh_home "$root" -c exit > /dev/null 2>&1

    local probe
    probe="$(sandbox_zsh_home "$root" -c '
        print -r -- "zdotdir:$ZDOTDIR"
        print -r -- "conf:$zsh_dirs[conf]"
        print -r -- "require:$+functions[zsh_dirs_require]"
    ' 2> /dev/null)"

    sandbox_destroy "$root"

    local -a lines=("${(@f)probe}")

    assert "$lines[1]" same_as "zdotdir:$root/.config/zsh"
    assert "$lines[2]" same_as "conf:$root/.config/zsh"
    assert "$lines[3]" same_as 'require:1'
}
```

Append to `tests/boot.zunit`:

```zsh
@test 'A home startup link starts the interactive runtime' {
    # The interactive half of spec criterion A6; see the note on the same
    # test in env.zunit. .zshrc is found through the ZDOTDIR that
    # env/zsh_dirs.env.zsh assigns, not one inherited from anywhere.
    sandbox_global_sets_zdotdir "$SANDBOX" &&
        skip 'The global zshenv assigns ZDOTDIR, so ~/.zshenv is never read'

    local root
    root="$(sandbox_create)"
    sandbox_install_runtime "$root" > /dev/null
    ln -s -- "$root/.config/zsh/.zshenv" "$root/.zshenv"

    sandbox_zsh_home "$root" -i -c exit > /dev/null 2>&1

    local probe
    probe="$(sandbox_zsh_home "$root" -i -c '
        print -r -- "rc:$zsh_dirs[rc]"
        print -r -- "complete:$+functions[_main_complete]"
        print -r -- "plugins:${#zsh_plugins_loaded}"
    ' 2> /dev/null)"

    sandbox_destroy "$root"

    local -a lines=("${(@f)probe}")

    assert "$lines[1]" same_as "rc:$root/.config/zsh/rc"
    assert "$lines[2]" same_as 'complete:1'
    assert "$lines[3]" different_to 'plugins:0'
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `mise x -- zunit run --tap tests/env.zunit tests/boot.zunit`

Expected: the cold-stdout test PASSES already; it is pinned by Step 5's break.
Both portable tests FAIL with `command not found: sandbox_global_sets_zdotdir`.

- [ ] **Step 3: Add the helpers**

Append to `tests/_support/sandbox.zsh`:

```zsh
#
# Run zsh against a sandbox as a machine with no ZDOTDIR and no XDG variable
# would: only HOME, PATH, TERM and SHELL, plus the mise trust that every
# sandbox start carries. zsh then finds its configuration through ~/.zshenv,
# which is the portable installation contract.
#
function sandbox_zsh_home() {
    emulate -L zsh

    local root="$1"
    shift

    env -i \
        HOME="$root" \
        PATH="$PATH" \
        TERM="${TERM:-dumb}" \
        SHELL="${commands[zsh]:-/usr/bin/zsh}" \
        MISE_TRUSTED_CONFIG_PATHS="$ZSH_REPO_ROOT" \
        zsh "$@"
}

#
# Succeed when this machine's global zshenv assigns ZDOTDIR itself.
#
# zsh reads the global zshenv before anything else, even under -f, so where it
# assigns ZDOTDIR zsh never consults ~/.zshenv, and a test of portable startup
# would pass without exercising it. Arch here does this; Ubuntu on CI does not.
#
function sandbox_global_sets_zdotdir() {
    emulate -L zsh

    local set
    set="$(env -i HOME="$1" PATH="$PATH" zsh -fc 'print -r -- ${+ZDOTDIR}')" ||
        return 1

    [[ "$set" == 1 ]]
}
```

- [ ] **Step 4: Run the tests**

Run: `mise run test`

Expected: PASS, 122 tests. On this machine both portable tests report
`# SKIP The global zshenv assigns ZDOTDIR`. Confirm the probe itself:
`zsh -fc 'source tests/_support/sandbox.zsh; sandbox_global_sets_zdotdir /tmp && print yes'`
prints `yes` here.

- [ ] **Step 5: Watch them fail**

1. In `zsh/env/zsh_dirs.env.zsh`, temporarily change
   `print -u2 "Creating zsh directories"` to `print "Creating zsh directories"`.
   Run `mise x -- zunit run --tap tests/env.zunit`. Expected: the cold-stdout test fails
   with a byte count above zero. Restore with
   `git restore zsh/env/zsh_dirs.env.zsh`.
2. The portable tests skip locally, so observe them where they run. Preferred,
   with nothing pushed: `act workflow_dispatch -j test` (act is on `PATH`
   through mise), first with both tests' `ln -s` lines commented out (expect
   both to fail on `zdotdir:` and `rc:`), then restored (expect both to pass).
   If act cannot run the job, ask the user before the fallback: push the
   broken state to `scratch/portable-probe`, run
   `gh workflow run lint.yaml --ref scratch/portable-probe`, read the result with
   `gh run view --log`, then delete the scratch branch. Neither the push nor
   the run triggers `sync-header-metadata`, which listens only on `main` and
   on pull requests.

- [ ] **Step 6: Commit**

```bash
git add tests/_support/sandbox.zsh tests/env.zunit tests/boot.zunit
git commit -m "test: Cover cold and portable startup"
```

---

### Task 5: Project tooling outside the gates

Neither file is exercised by `mise run lint` or `mise run test`, so each is
verified by hand as `AGENTS.md` ("Neovim project tooling") describes.

**Files:**

- Modify: `.nvim.lua:34-38`
- Modify: `.worktreeinclude`

**Interfaces:**

- Consumes: the `zsh/` layout from Task 2.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Observe the current failure**

```bash
nvim --headless -n -i NONE -c 'source .nvim.lua' \
    -c 'edit zsh/func/__plan_probe' \
    -c 'lua vim.wait(2000, function() return #vim.fn.getline(1, "$") > 12 end)' \
    -c 'lua io.stdout:write(table.concat(vim.fn.getline(1, "$"), "\n"), "\n")' \
    -c 'qa!'
```

Expected: no template body (no `emulate -L zsh`), and most likely an empty
buffer. `.nvim.lua` still classifies paths under the repository root, and its
`vim.filetype.add` patterns are anchored there too, so this extensionless file
gets no `zsh` filetype, and nvim-config therefore writes no header either.

- [ ] **Step 2: Classify files under `zsh/`**

In `.nvim.lua`, replace:

```lua
-- Resolved from this file rather than from cwd, since exrc also picks up a
-- `.nvim.lua` from any parent of the directory Neovim was started in
local root     = vim.fs.dirname(
    vim.fs.abspath(assert(debug.getinfo(1, "S")).source:sub(2))
)
```

with:

```lua
-- Resolved from this file rather than from cwd, since exrc also picks up a
-- `.nvim.lua` from any parent of the directory Neovim was started in. The
-- source directories classified below are children of the runtime, `zsh/`,
-- not of the repository root this file sits in
local root     = vim.fs.joinpath(
    vim.fs.dirname(
        vim.fs.abspath(assert(debug.getinfo(1, "S")).source:sub(2))
    ),
    "zsh"
)
```

`root_pat`, `kind_of` and the `vim.filetype.add` patterns all derive from
`root` and need no further edit.

- [ ] **Step 3: Verify the editor tooling**

1. Re-run Step 1's probe. Expected: line one `#!/bin/false`, a
   `# ::: :/zsh/func/__plan_probe` header line, then the `func` template body
   including `emulate -L zsh` and the `local __this_file=` line.
2. Run it again with `edit func/__plan_probe`. Expected: no template body.
3. `luafmt --check --stdin-filename .nvim.lua < .nvim.lua` exits 0.
4. `selene .nvim.lua` reports no errors.
5. `VIMRUNTIME="$(nvim --clean --headless -c 'lua io.stdout:write(vim.env.VIMRUNTIME)' -c q)" emmylua_check .`
   reports no new diagnostics.
6. `ls zsh/func/__plan_probe` fails: the probe never wrote the file.

- [ ] **Step 4: Commit the editor change**

```bash
git add .nvim.lua
git commit -m "chore: Point editor templates at zsh/"
```

- [ ] **Step 5: Stop copying the runtime's `env/` into worktrees**

`env*` carries no slash, so it matches at any depth: it names `zsh/env/` and
would copy a generated `zsh/env/chezmoi.env.zsh`, with one machine's paths,
into every new worktree. The intended target is the untracked `.env*` family
that `.gitignore` ignores. Replace the file's body below the header with:

```gitignore
# Untracked local environment overrides, as .gitignore names them. The leading
# dot matters: a bare env* also matches the runtime's env/ directory at any
# depth, and would copy a generated env/chezmoi.env.zsh, with this machine's
# paths, into the new worktree.
.env*
*.local.*
/node_modules/
```

- [ ] **Step 6: Verify and commit**

Run: `mise run lint`

Expected: PASS (Prettier ignores the file type; no other check reads it).

```bash
git add .worktreeinclude
git commit -m "chore: Stop copying env/ into new worktrees"
```

---

### Task 6: Documentation

**Files:**

- Modify: `AGENTS.md` (sections listed below)
- Modify: `docs/spec/2026-11-03_runtime-directory-separation.md` (status row)

**Interfaces:**

- Consumes: names from Tasks 1 to 5: `ZSH_REPO_ROOT`, `ZSH_CONFIG_ROOT`,
  `sandbox_install_runtime`, `sandbox_zsh_home`,
  `sandbox_global_sets_zdotdir`, `tests/layout.zunit`.

- [ ] **Step 1: Repository section**

Replace line 31,
"Effective when `ZDOTDIR` is equal to the directory path of the repository
root.", with:

```markdown
The runtime is the `zsh/` directory: `.zshenv`, `.zshrc` and the seven module
directories. It is effective when `ZDOTDIR` names that directory, and nothing
in it reads from the repository around it. Everything else at the root is
project tooling. Throughout this file, a runtime path such as `rc/` or
`env/zsh_dirs.env.zsh` is relative to `zsh/`; a path naming a repository file,
such as `tests/` or `.mise.toml`, is relative to the root.
```

After the paragraph ending "then `git push local main`." insert:

```markdown
**Until the live cutover, do not push to `local`.** The live clone at
`~/.config/zsh` predates the move to `zsh/` and is itself the running
`ZDOTDIR`. Any commit from the move onward deletes `.zshenv` and `.zshrc` from
its root, and every new shell then starts unconfigured. The cutover replaces
that clone with one whose `zsh/` child is linked at `~/.config/zsh`, in the
order `docs/spec/2026-11-03_runtime-directory-separation.md` sets out under
"Initial Cutover and Recovery". Remove this paragraph once that has been done.
```

- [ ] **Step 2: Installation section**

Insert a new section directly before "## Loading architecture":

```markdown
## Installation

`ZDOTDIR` must name the runtime directory itself, never the repository root.
The intended live arrangement keeps a separate clone outside the configuration
path and links only its `zsh/` child into place:

    ~/.local/share/zsh-config/          live clone, the `local` remote
    ~/.config/zsh -> ~/.local/share/zsh-config/zsh

Where nothing supplies `ZDOTDIR`, zsh reads `~/.zshenv`. For the default
configuration path, link that to `~/.config/zsh/.zshenv`; the runtime finds
itself through its own `${XDG_CONFIG_HOME:=$HOME/.config}/zsh` fallback. A
runtime installed anywhere else needs `ZDOTDIR` set before that file is read.
The live clone needs no development dependencies to start a shell.
```

In `AGENTS.md`, write the two-line diagram as a fenced `text` block; it is
indented here only so the fences do not nest.

- [ ] **Step 3: Directory purposes, conventions, workflows, assets**

- In the `env/` bullet, replace "It is gitignored for that reason." with "It
  is gitignored, as `/zsh/env/chezmoi.env.zsh`, for that reason." Replace "the
  sandbox links the whole checkout, so that file points the test shell at the
  real dotfiles, and `tests/header.zunit` and `tests/boot.zunit` both fail on
  it." with "the sandbox links the checkout's runtime, so that file would
  point the test shell at the real dotfiles; `tests/layout.zunit` fails on
  sight of it."
- In "## Conventions", after "a comment naming the file's own repo-relative
  path", add "(`zsh/rc/completion.rc.zsh`, not `rc/completion.rc.zsh`)".
- In "## GitHub workflows", change "keyed on `spec/*.spec.zsh` and
  `rc/completion.rc.zsh`" to "keyed on `zsh/spec/*.spec.zsh` and
  `zsh/rc/completion.rc.zsh`".
- In "## Claude Code assets", change "`env*`, `*.local.*` and
  `node_modules/`." to "`.env*`, `*.local.*` and `node_modules/`. The leading
  dot matters: a bare `env*` also matched the runtime's `env/`, and with it a
  generated `chezmoi.env.zsh`."
- In "## Toolchain and tasks", after the `lint:syntax` description "(`zsh -n`
  over every shell file, with exactly one carve-out: `tests/*.zunit`, for the
  reason below)", add the sentence "It also fails when a tracked shell file is
  missing from its globs, since each one carries `(N)` and would otherwise
  drop a directory in silence."
- In "## Neovim project tooling", change "a new file in `func/`, `wrap/`,
  `util/` or `spec/`" to "a new file in `zsh/func/`, `zsh/wrap/`, `zsh/util/`
  or `zsh/spec/`".

- [ ] **Step 4: Tests section**

In "### Layout", add after the `tests/header.zunit` bullet:

```markdown
- `tests/layout.zunit` - the layout contract: both helpers derive the same two
  roots from any directory, the runtime lives beneath `zsh/` and nowhere else,
  and the generated `chezmoi.env.zsh` stays ignored and absent.
```

Extend the `tests/header.zunit` bullet with ", and that every tracked shell
file is among those checked". Extend the `tests/_support/` bullet's
`sandbox.zsh` clause to "builds and tears down the throwaway `HOME`, and can
install a tracked-only copy of the runtime".

At the start of "### Sandboxing", insert:

```markdown
The helpers keep two roots. `ZSH_REPO_ROOT` is the repository, derived from
the helper's own path; `ZSH_CONFIG_ROOT` is `$ZSH_REPO_ROOT/zsh`, the runtime.
Runtime discovery, autoloading and the sandbox's configuration link use the
second. Test discovery, header paths and `MISE_TRUSTED_CONFIG_PATHS` use the
first, since `.mise.toml` stays at the root.

`sandbox_install_runtime` copies only the files git tracks under `zsh/` into
`.local/share/zsh-config/` inside the sandbox, and points `.config/zsh` at its
`zsh/` child, mirroring the live installation. `sandbox_zsh_home` starts zsh
with neither `ZDOTDIR` nor any XDG variable, so it is found through
`~/.zshenv`. That only works where the global zshenv leaves `ZDOTDIR` unset.
This machine's assigns it even under `zsh -f`, so the two portable-startup
tests skip here through `sandbox_global_sets_zdotdir` and run on CI. The same
global file also assigns the XDG variables, so `sandbox_zsh_bare` exercises
their fallbacks fully only on CI.
```

In the paragraph listing conditional skips, change "the plugin-cache guard on
`tests/boot.zunit`, and a test whose subject is absent" to "the plugin-cache
guard on `tests/boot.zunit`, the two portable-startup tests where the global
zshenv assigns `ZDOTDIR`, and a test whose subject is absent".

- [ ] **Step 5: Specification status**

In `docs/spec/2026-11-03_runtime-directory-separation.md`, change the status
row's value to
`Implemented in source; live installation cutover pending`, and set the
front matter `mtime` to the date of the change.

- [ ] **Step 6: Verify and commit**

```bash
grep -nP '\x{2014}' AGENTS.md docs/spec/2026-11-03_runtime-directory-separation.md
mise run fmt && mise run lint
```

Expected: no output from `grep`; lint PASS. Read the diff once for accuracy
against the tree as it now stands.

```bash
git add AGENTS.md docs/spec/2026-11-03_runtime-directory-separation.md
git commit -m "docs: Describe the zsh/ runtime layout"
```

---

### Task 7: Acceptance and pull request

**Files:** none modified, unless a check below fails.

- [ ] **Step 1: Run every check from a clean tree**

```bash
git status --short
mise run lint && mise run test
```

Expected: clean tree, both PASS, 122 tests. The only skips are the fzf test
where fzf is installed and the two portable-startup tests.

- [ ] **Step 2: Walk the acceptance criteria**

| ID  | Evidence in this branch                                                                                             |
| --- | ------------------------------------------------------------------------------------------------------------------- |
| A1  | `tests/layout.zunit`: runtime beneath `zsh/` and nowhere else; the install fixture reaches nothing outside its copy |
| A2  | Step 1 locally; Step 4 on CI, with `tests/boot.zunit` not skipped                                                   |
| A3  | `A runtime under a hostile directory name loads each module once`                                                   |
| A4  | `An installed copy of the tracked runtime starts on its own`                                                        |
| A5  | Cold and warm stdout byte tests; warm stderr test; insecure-path compinit test                                      |
| A6  | `sandbox_zsh_bare` XDG test; both portable-startup tests on CI                                                      |
| A7  | Header tests over `zsh/` and `tests/`; Task 5 Step 3 editor probes                                                  |
| A8  | `Starting the shell clones nothing`; the two chezmoi layout tests                                                   |
| A9  | New `hashFiles` inputs on CI; PATH stripped of repository tool directories in the install fixture                   |
| A10 | Out of scope: the later installation task                                                                           |

Any row without evidence is a gap to fix before going on.

- [ ] **Step 3: Push and open the pull request**

Ask the user before pushing. With their go-ahead:

```bash
git push -u origin refactor/runtime-directory
gh pr create --title "refactor: Move the runtime beneath zsh/" --body-file -
```

In the body, summarise the tasks and the A1 to A9 evidence table, and state
that the live cutover (A10) is a separate task and that `local` must not be
pushed in the meantime.

- [ ] **Step 4: Confirm CI**

```bash
gh pr checks --watch
run="$(gh run list --branch refactor/runtime-directory --workflow lint.yaml \
    --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run view "$run" --log | grep -E 'SKIP|1\.\.[0-9]+'
```

Expected: every check green. In the test log, the plugin cache misses once
under its new key, and neither portable-startup test, nor anything in
`tests/boot.zunit`, reports `SKIP`. Pull any `chore: Sync header metadata`
commit with `git pull` before pushing again.

- [ ] **Step 5: Hand off**

Use superpowers:finishing-a-development-branch. After the merge, pull `main`
here and stop. Do not `git push local main`: the next step is the separately
planned installation task described in the specification.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
