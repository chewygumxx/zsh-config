# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

Absolutely no em dashes are to be employed within this repository.

Ensure any printed conversation output line length is limited to 80 characters
except where it may be unfeasable to do so eg. URL.

## Repository

Personal Zsh shell configuration dotfiles (`~chewygumxx/zsh-config`). It is used
by pointing `ZDOTDIR` at this directory; there is no install script, so the
loading architecture below only takes effect once `ZDOTDIR` is set to this repo.

Note that `~/.config/zsh` is a separate clone of this same repository and is the
live configuration. This checkout is the source; commits here do not affect the
running shell until they are pushed or pulled across. `origin` carries a second
push URL pointing at that live checkout.

On this machine `/etc/zsh/zshenv` supplies `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`,
`XDG_DATA_HOME`, `XDG_STATE_HOME` and `ZDOTDIR`. That file is machine-local and
not part of this repo, so nothing here may depend on it.

## Loading architecture

Two entry points, sourced by zsh itself:

- `.zshenv` - sourced for every zsh invocation, interactive or not. Sources
  every `env/*.env.zsh` file in glob order, which is plain alphabetical order
  with no reordering logic. Because it runs for non-interactive shells too,
  nothing reachable from here may write to stdout: doing so corrupts the stream
  that `scp`, `rsync`, `sftp` and `git` over ssh read as protocol data.
  Diagnostics go to stderr via `print -u2`.
- `.zshrc` - sourced only for interactive shells (guarded by
  `[[ -o interactive ]] || return`). Globs `rc/*.rc.zsh`, then explicitly
  reorders that list before sourcing: `ls_colors` first, then `completion`, then
  `function`, then everything else, then appends `util/*.rc.zsh`. This
  reordering is load-bearing: `completion.rc.zsh` wants a minimal `fpath` when
  it builds the completion index, and other rc files call functions that
  `function.rc.zsh` has to autoload first.

The reorder patterns are anchored to the final path component
(`*/completion.rc.zsh`), not bare substrings. Matching `*completion*` tested the
whole absolute path, so any config directory whose name contained `completion`,
`function` or `ls_colors` misclassified every file beneath it and could source
files twice.

`.zshrc` sources each file inside a nested anonymous function. That wrapper is
load-bearing rather than redundant: it is what makes a top-level `local` legal
inside each rc file, as used in `rc/function.rc.zsh` and `rc/plugin.rc.zsh`. Do
not remove it.

All directory globs carry the `(N)` qualifier. Without it an empty or missing
directory raises `no matches found`, which aborts the whole array literal and
leaves zero files sourced.

### `zsh_dirs`

`env/zsh_dirs.env.zsh` defines the `zsh_dirs` associative array that nearly
everything else depends on, and creates whichever of those directories are
missing on every start. It tests each one rather than trusting a stamp file: a
stamp outside the tree survived the tree's deletion, so nothing was recreated
and completion silently disappeared. Its keys are:

- Source, derived from `${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}`:
  `conf`, `env`, `comp`, `func`, `wrap`, `rc`, `util`, `spec`.
- Cache, under `XDG_CACHE_HOME`: `cache`, `cache_comp`, `cache_init`,
  `cache_zstylecomp`, `cache_zvm`.
- Data, under `XDG_DATA_HOME`: `share`, `share_func`, `share_comp`, `plugin`.
- State, under `XDG_STATE_HOME`: `state`.

Source paths follow `ZDOTDIR` so a checkout sourced from anywhere loads its own
files; the cache, data and state paths deliberately do not, since those are
per-user state rather than part of the checkout.

Every XDG variable is read with a `:-` fallback. Those variables come from
systemd, which is not applied in every context, and without a fallback every
path collapsed to a root-relative one such as `/zsh` where `mkdir -p` fails on
each shell start. The cache fallback is `$HOME/.local/cache`, matching the local
convention rather than the XDG default of `~/.cache`.

The array is declared and assigned in a single `typeset -gA zsh_dirs=( ... )`
statement. Split across two statements, the subscripted keys are only valid once
`typeset -gA` has run, so `zsh -n` misparses the file. Keep it as one statement,
or `lint:syntax` will need an exemption again.

`zsh_dirs_require` is defined in the same file and is the shared validator.
Callers pass a label and the keys they intend to read:

```zsh
zsh_dirs_require "$__this_file" rc util || return 1
```

It checks that `zsh_dirs` is set, is an association, and that each named key
exists and is a directory, reporting `[CRITICAL]` or `[ERROR]` to stderr. Use it
rather than duplicating the checks. Reading an undefined key yields an empty
string silently, which is how an empty entry once reached `fpath` and made zsh
autoload out of the current working directory.

## Directory purposes

- `env/` - `*.env.zsh`, sourced by `.zshenv`; safe for non-interactive shells
  (env vars, `zsh_dirs`, fzf/ssh/claude env setup, and the per-tool XDG
  relocations in `env/tools.env.zsh`). A variable that decides where a tool
  keeps its state belongs here rather than in `rc/`, or scripts and
  `ssh host cmd` see a different value from the interactive shell.
- `rc/` - `*.rc.zsh`, interactive-only modules sourced by `.zshrc` (aliases,
  completion, directory hashes, function loading, history, ls_colors, plugin
  management, prompt).
- `func/` - one function per file; added to `fpath` and autoloaded by
  `rc/function.rc.zsh`.
- `wrap/` - wrapper functions for external CLIs (`eza`, `gh`, `nvim`, `rm`,
  etc.), also autoloaded from `fpath`. Files are named directly after the
  command they wrap. No aliases are involved: a defined function already takes
  precedence over a same-named external binary. Wrappers must therefore call the
  real binary via `command foo`, or they recurse into themselves. Wrappers often
  read a companion `__foo_opts` array defined in `util/`.
- `util/` - `*.rc.zsh` per-external-tool config (bat, chezmoi, eza, fzf, gtrash,
  linters, luarocks, nvm, systemd, zoxide), sourced last by `.zshrc`.
- `spec/` - `*.spec.zsh`, one per plugin, sourced by `rc/plugin.rc.zsh`. See
  below.
- `comp/` - completion definitions, on `fpath`; holds a tracked `.keep`
  placeholder.
- `patches/` - npm patch files applied via `patchedDependencies` in
  `package.json`; repo tooling, unrelated to the shell runtime.

## Plugin management

There is no plugin manager (no antidote, zinit, or zplug) and no git submodules.
`rc/plugin.rc.zsh` hand-rolls it, and the design is spec-driven rather than
list-driven: there is no `plugins` array anywhere.

The loader iterates every file in `$zsh_dirs[spec]`, sources each one, and reads
two variables out of it:

- `slug` - the GitHub `owner/repo` to clone. Required; a spec that does not set
  it is reported and skipped.
- `enabled` - set to the string `false` to skip that plugin. Any other value, or
  absent, means enabled.

A plugin counts as installed when its `$plugin.plugin.zsh` entry point is
readable, not merely when its directory exists. Testing the directory alone
treated a clone interrupted part way as permanently complete, so the plugin
silently never loaded again and was never re-cloned.

Cloning is done by `func/__plugin_clone`, which clones into a staging directory
beside the plugin and moves it into place only once the entry point is present.
Cloning straight into the plugin directory cannot repair an interrupted clone,
because `git clone` refuses a destination that exists and is not empty.

Neither the spec nor the plugin is sourced with stderr redirected. Discarding
those errors was the single largest reason breakage in this repo stayed
invisible.

`rc/completion.rc.zsh` clones `zsh-users/zsh-completions` and `aloxaf/fzf-tab`
itself, bypassing `spec/` entirely, though through the same helper. It
autoloads that helper by path, since `func/` is not on `fpath` until
`rc/function.rc.zsh` runs after it.

## Conventions

- Every `rc/`, `env/`, `util/`, `func/`, `wrap/` and `spec/` file, plus
  `.zshenv` and `.zshrc`, opens with the same header block: `#!/bin/false`, then
  `# vim:set expandtab shiftwidth=4 filetype=zsh:`, then
  `# SPDX-License-Identifier: GPL-3.0-only`, then a comment naming the file's
  own repo-relative path. These files are only ever sourced or autoloaded, so
  `#!/bin/false` is deliberate: it prevents accidental direct execution.
- Loops and scoped locals are commonly wrapped in anonymous functions
  (`() { local x; ... }`, often with `emulate -L zsh`) to avoid leaking
  variables into the sourcing shell.
- Files that depend on `zsh_dirs` call `zsh_dirs_require` before proceeding
  rather than trusting it.
- `local +h functions` does **not** scope function definitions; zsh defines
  functions globally regardless. To keep a helper out of the interactive
  namespace, either `trap 'unset -f helper' EXIT` (an EXIT trap set inside a
  function runs when that function returns) or wrap the entry point in
  `{ ... } always { ... }` capturing and re-returning the status, as `wrap/gh`
  and `wrap/chezmoi` do.

### Zsh traps worth remembering

These each caused a real, long-lived bug here:

- `[[ ]]` performs **no filename generation**. A glob qualifier inside it is
  never expanded, so `[[ -n "$file"(Nmh-24) ]]` tests a non-empty literal string
  and is unconditionally true. Evaluate the glob through an array assignment
  instead.
- `-v` on a scalar is true as soon as `local name` has declared it, with or
  without a value. Guards written as `[[ ! -v name ]]` after a `local name` are
  dead code; test `[[ -z "$name" ]]`.
- `"${arr[@]}"` on an **unset** array expands to one empty string in zsh, unlike
  bash. On a declared but empty array it correctly yields nothing. Prefer plain
  `$arr`, which yields no words and still preserves elements containing spaces,
  since zsh does not word-split parameters.
- `trap` takes its arguments as `trap ACTION SIGNAL`. Reversed, it reports
  `undefined signal` and installs nothing. Interpolate any local you need into
  the action with double quotes and `(q)`, because a single-quoted action is
  expanded when the trap fires, by which point function locals are out of scope.
- `print` parses arguments beginning with `-` as its own options. Pass `--`
  before data that starts with a dash, or help text documenting a `-u` flag
  aborts with `number expected after -u`.
- `-s` is true when a file exists and is **non-empty**. Several tests here were
  written negated by mistake, so they acted on exactly the opposite condition.
- `zstat` requires `zmodload -F zsh/stat b:zstat`. The bare `zmodload zsh/stat`
  also defines a `stat` builtin that shadows `/usr/bin/stat` for the session.

## Commit messages

Commits are linted by commitlint (`@commitlint/config-conventional`) via a Husky
`commit-msg` hook, so commit messages must follow Conventional Commits. Use
`mise run commit` (Commitizen, same as `npm run commit`) to be walked through a
compliant message interactively, or check the last one with
`mise run lint:commit`.

Two rules in `.commitlintrc.mts` are stricter than the defaults and are easy to
trip over:

- `header-max-length` is **50**, not 72.
- `scope-enum` permits only `env`, `rc`, `util`, `func`, `wrap`, `spec`, `comp`.
  Scopes used earlier in the repo's history, such as `zsh`, `chezmoi` and
  `systemd/ssh`, now fail. Changes to root-level files take a bare `type:` with
  no scope.

`subject-case` wants start case or sentence case, and `body-max-line-length`
is 72.

## Toolchain and tasks

Tool versions and repo tasks are declared in `.mise.toml`. `mise install`
provisions npm, Node, `actionlint`, and `shuck`. `shuck` is not carried in the
mise registry, so it is pulled from its GitHub releases through the `github:`
backend, with the binary named explicitly because the release assets are called
`shuck-cli-*`. Tasks prepend `node_modules/.bin` to `PATH`, so they call `tsc`,
`prettier`, `commitlint` and `cz` directly instead of paying an `npx`
resolution.

`npm:npm` is pinned to 12 and is declared **before** `node` on purpose. mise
contributes bin directories to `PATH` in the order tools appear, and Node ships
an npm of its own, so listing it second leaves Node's bundled npm shadowing the
pinned one. npm 12 is required because `patchedDependencies`, and the
`npm patch` family that maintains it, are npm 12 features: Node 22 bundles npm
10 and Node 24 bundles npm 11, and with either the patch under `patches/` is
ignored on install in complete silence. `.npmrc` sets `engine-strict=true` so
the `engines` block in `package.json` makes that a hard failure instead.
`.github/workflows/commitlint.yaml` upgrades npm explicitly before `npm ci` for
the same reason.

If the patch file itself is edited, `package-lock.json` records an integrity
hash of it and `npm ci` will refuse with
`does not match the patch recorded in the lock file`. Run `npm install` to
resync the lock.

Node is pinned to the major that `.github/workflows/commitlint.yaml` installs,
currently 24, which is the floor set by `.github/workflows/CLAUDE.md`.

Run `mise tasks` for the full list. The entry points:

- `mise run setup` - `npm ci`, which also installs the Husky hooks.
- `mise run lint` - every non-interactive check.
- `mise run test` - the zunit suite, against a throwaway `HOME`.
- `mise run fmt` - rewrites files in place, via `shuck format` and Prettier.
- `mise run commit` - the interactive Commitizen prompt.

`lint` fans out to `lint:zsh` (`shuck check`, configured by `.shuck.toml`),
`lint:syntax` (`zsh -n` over every shell file, with exactly one carve-out:
`tests/*.zunit`, for the reason below), `lint:actions` (`actionlint`),
`lint:types` (`tsc` over `.commitlintrc.mts`, the only TypeScript file in the
repo), and `lint:format` (`shuck format --check`, then `prettier --check .`).
`lint:commit` inspects the most recent commit message and is deliberately kept
out of the aggregate, since it depends on `HEAD` rather than on the working
tree.

`lint:actions` carries a deliberate exclusion, commented inline in `.mise.toml`:
it ignores a known `actionlint` false positive against
`actions/create-github-app-token@v3`, where `client-id` is in fact valid and
`app-id` is not required.

`test` is deliberately not wired into `lint`, nor `lint` into `test`. `lint`
reads the working tree and nothing else, whereas `test` spawns real shells
against a scratch `HOME`, so the two are worth running apart.
`.husky/pre-commit` runs both, and `.github/workflows/lint.yaml` runs them as
two jobs.

Prettier does not read `.gitignore`, so untracked tool state is listed again in
`.prettierignore`.

## Hooks

`.husky/` carries two hooks, both tracked and both mode 755. `commit-msg` runs
commitlint. `pre-commit` runs `mise run lint` then `mise run test` over the
whole working tree, and rewrites nothing; use `mise run fmt` for that.

Everything in a hook has to go through `mise run`. Husky invokes hooks under
`sh -e` and prepends only `node_modules/.bin` to `PATH`, so mise's tool
directories are absent and `shuck`, `actionlint` or `zunit` called by name would
exit 127. `pre-commit` therefore checks for `mise` first and fails loudly when
it is missing, because a hook that goes green when its tooling is absent is
worse than no hook at all.

`.husky/_/` already holds a generated shim for every git hook, and the `h`
dispatcher exits 0 when the top-level counterpart is absent, so adding a file at
`.husky/<hook>` is live immediately with no need to re-run `husky`.

## Tests

`mise run test` runs zunit over `tests/`. The suite is the executable form of
the procedure that "Verifying changes" used to describe in prose.

### Provisioning

`test:deps` fetches two single-file zsh scripts into a gitignored `.bin/`, each
pinned to a tag and checked against a recorded sha256; a mismatch deletes the
file and fails the task. `.bin` is added to `_.path` in `.mise.toml`, listed
after `node_modules/.bin` so a genuinely installed tool always wins.

Neither tool can live in the `[tools]` table. zunit is absent from the mise
registry and publishes one generic release asset rather than the platform-tagged
set the `github:` backend matches on, and revolver publishes no release assets
whatsoever. revolver is not optional: zunit's entry point runs `type revolver`
and exits before parsing a single option, so it is required even with `--tap`.

zunit's most recent release is 0.8.2, from January 2018. Quiet upstream, but not
archived.

### Layout

- `tests/boot.zunit` - startup regressions: clean stderr, byte-empty stdout, no
  empty `fpath` element, the shape and key set of `zsh_dirs`, the source versus
  state path split, `zsh_dirs_require`, and which specs load.
- `tests/env.zunit` - what `.zshenv` and `env/` set up. It starts only
  non-interactive shells, which never clone, so unlike `boot.zunit` it needs no
  borrowed plugin clones and always runs.
- `tests/func.zunit` and `tests/wrap.zunit` - unit tests for `func/` and
  `wrap/`.
- `tests/header.zunit` - header block conformance, including that every
  `# ::: :/<path>` line matches the file's real location, which is what catches
  a copied file.
- `tests/_support/` - `sandbox.zsh` builds and tears down the throwaway `HOME`;
  `autoload.zsh` puts `func/` and `wrap/` on `fpath` and writes stub binaries.
- `tests/_output/` - zunit's generated logs. Gitignored and prettierignored.

Both underscore-prefixed directory names are load-bearing, not stylistic:
zunit's discovery skips any path whose basename begins with an underscore.

Three tests in `tests/wrap.zunit` are `skip`ped on purpose, each recording a
defect found while the suite was being written: `wrap/jq` tests
`(($+@[--indent]))`, which is not a valid subscript idiom and raises
`bad math expression` on stderr for every `jq` call while never being true, so
`--indent 4` is injected ahead of whatever the caller passed; `wrap/chezmoi`
assigns `__this__file` but interpolates `__this_file`; `wrap/sv` does the exact
reverse. Remove the skip along with the fix.

### Sandboxing

`sandbox_create` builds a scratch `HOME`, symlinks the checkout to
`$XDG_CONFIG_HOME/zsh`, and sets every XDG variable, so that no value inherited
from the calling shell can point the configuration at the live tree.
`sandbox_zsh_bare` passes no XDG variable at all, which is how
`tests/env.zunit` proves that every XDG read has a fallback: unset, those
variables once collapsed paths to root-relative ones such as `/cargo/bin`.
Directories are created `0755` so that nothing the fixture makes is ever
world-writable.

`rc/completion.rc.zsh` passes `compinit -i`, and that flag is load-bearing.
Without it a single world-writable directory anywhere on `fpath`, including one
outside this checkout, sends `compinit` to a prompt; a shell with no terminal
cannot answer, so it prints `not interactive and can't open terminal` then
`compinit: initialization aborted` and leaves the shell with no completion at
all. This is not hypothetical: it is what the first CI run of the test workflow
caught. Note that group-writable does not trigger it, only other-writable, and
that `compinit -C` skips the audit entirely, so the fault only appears on a cold
cache. `tests/boot.zunit` pins it with a sandbox of its own, left deliberately
unwarmed for that reason.

`-i` alone did not fix CI. Debian and Ubuntu ship an `/etc/zsh/zshrc` that runs
a bare `compinit` before `$ZDOTDIR/.zshrc`, so the abort came from that call
instead. `.zshenv` sets `skip_global_compinit=1`, the documented opt-out, and
that is equally load-bearing. Arch ships no such file, so it never reproduces
locally; on an Ubuntu box, `chmod 0777` a system `fpath` directory to see it.

Nothing in the fixture exports into the calling shell. zunit runs every test as
a function inside one process, so an exported variable would leak into each
later test; `sandbox_zsh` passes the environment explicitly through `env -i`
instead.

Plugin clones are borrowed from `$ZSH_TEST_PLUGIN_DIR`, else
`$XDG_DATA_HOME/zsh/plugins`. An explicitly set `ZSH_TEST_PLUGIN_DIR` is
authoritative and never falls back to the live cache. They are linked in **one
entry at a time**, never as a single directory symlink: were the directory
itself linked, a plugin that happened to be missing would have
`rc/plugin.rc.zsh` clone it straight into the live cache. The `(N/)` qualifier
also steps over the stray `history` file that sits in that directory.

With no usable cache, the whole of `tests/boot.zunit` skips. That is
deliberately file-wide rather than per-test: every assertion there starts a full
interactive shell, and a full start has `rc/plugin.rc.zsh` and
`rc/completion.rc.zsh` clone anything missing, so without clones to borrow the
entire file would reach the network. A directory that exists but holds no clones
is rejected for the same reason. One test asserts that every entry under the
sandbox plugin directory is still a symlink afterwards, and that is what
actually pins the suite offline.

The first start of a fresh sandbox legitimately writes to stderr:
`env/zsh_dirs.env.zsh` announces `Creating zsh directories`, and the chezmoi,
luarocks and zoxide helpers each announce the cache they are regenerating.
`sandbox_warm` throws that first start away, which is what allows a later
start's stderr to be treated as a genuine fault.

### zunit traps worth remembering

Each of these cost real time here:

- **`equals` is arithmetic; `same_as` is the string comparison.** `equals`
  compares with `[[ -eq ]]`, so zsh evaluates both sides as math expressions,
  bare words resolve as parameters, and two unset parameters are both zero.
  `assert association equals banana` passes. Use `same_as` for anything that is
  not a number. Note that `same_as` leaves its comparison unquoted, making it a
  pattern, whereas `contains` quotes and so is literal.
- **`run` merges the streams.** It captures `2>&1` into `$output` and strips
  trailing newlines. An assertion about one specific stream has to separate them
  before `run` sees them, and a byte-exact check needs `wc -c` rather than
  `$output`, since a lone newline would otherwise vanish.
- **A `.zunit` file is not valid zsh.** `zsh -n` rejects `@test 'name' { ... }`
  with a parse error at the closing brace, so these files are excluded from
  `lint:syntax` and from `.shuck.toml`. This is the cost of zunit over a
  hand-rolled runner.
- **`tests/_support/*` has to be mapped in `.shuck.toml`.** Left unmapped, shuck
  reads those files as sh, where `$+functions[...]` means nothing, and
  `shuck format` rewrites `(($+functions[x]))` into `(($ + functions[x]))`: an
  expression that is true when the function is absent and false when it is
  present.
- **`shuck format` caches its results.** After an edit it can reformat from
  stale content, so `--no-cache` is the reliable check.
- **revolver writes into `$ZDOTDIR`.** Its state directory defaults to
  `${REVOLVER_DIR:-${ZDOTDIR:-$HOME}/.revolver}`, and `ZDOTDIR` on this machine
  is the live configuration, itself a checkout of this repository, so a
  `zunit run` without `--tap` drops untracked state files into the wrong clone.
  `.mise.toml` sets `REVOLVER_DIR` under `tests/_output/` and `.revolver/` is
  ignored as a safety net.
- The shebang must be `#!/usr/bin/env zunit` on **line one exactly**. zunit
  reads only the first line when deciding whether a file is a test file, and
  rejects it with exit 126 otherwise. The rest of the usual header block follows
  underneath.
- Test names must be **single-quoted**; name extraction indexes to the first and
  last `'` on the line. A test's closing `}` must be a **bare brace at column
  zero**, because an indented one is swallowed into the body.
- `.zunit.yml` must use **two-space** indentation. zunit parses it with a sed
  and awk pass that derives nesting from `length($1) / 2`, so four spaces
  produce `zunit_config_directories__tests` and the output and support
  directories silently fall back to defaults. Prettier would impose four,
  following `.editorconfig`, so `package.json` carries a `tabWidth: 2` override
  for that one file.
- `skip` exits 48, `fail` exits 1 and `error` exits 78. With
  `allow_risky: false`, a test that passes having asserted nothing is an error,
  so pair a `fail` message with an assertion rather than relying on `pass`.
- zunit offers `exists` but no negation of it. Count absence through an array
  assignment such as `local -a leftover=("$path"(N))`, which is also the only
  way a glob qualifier is expanded at all, since `[[ ]]` performs no filename
  generation.

## Verifying changes

`mise run test` is the check; `mise run lint` does not exercise the shell at
all. CI runs both, and `.husky/pre-commit` runs both before a commit lands.

Note that a plain `zsh -ic` on this machine loads the live `~/.config/zsh`, not
this checkout, so it is not a valid test of changes made here. That is precisely
what the sandbox exists for.

When adding an assertion, break the thing it guards and watch it fail before
trusting it green. Several assertions in this suite passed vacuously on the
first attempt.
