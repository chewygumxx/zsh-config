---
ctime: 2026-11-03
mtime: 2026-11-03
spdx: GPL-3.0-only
title: Runtime Directory Separation
description: >-
  Proposed design for placing the effective Zsh configuration beneath zsh/,
  separating repository and runtime paths in tests, and preserving deliberate
  live deployment.
tags:
  - spec
---

<!--
   -
   - ~chewygumxx/zsh-config.git
   - ::: :/docs/spec/2026-11-03_runtime-directory-separation.md
   -
   -->

# Runtime Directory Separation

| Design   | Value                                                                              |
| -------- | ---------------------------------------------------------------------------------- |
| Date     | 2026-11-03                                                                         |
| Baseline | Repository source layout at `0edc44e`                                              |
| Status   | Proposed; documentation requested, implementation and deployment pending           |
| Method   | Superpowers brainstorming workflow, using the preceding architectural discussion   |
| Scope    | Runtime location, test interfaces, project tooling, and installation compatibility |

This specification develops the recommendation recorded in the
[repository layout assessment](./../notes/2026-11-03_repository-layout-assessment.md).
It defines a future migration. Committing this document does not move the
configuration, change the live clone, or establish that the acceptance
criteria below have passed.

## Problem and Intended Outcome

The repository root is both the development workspace and the effective
`ZDOTDIR`. Runtime modules, test infrastructure, package dependencies, agent
assets, and project configuration consequently share the same root. Test
helpers also use one root variable for both runtime files and repository
infrastructure.

The intended outcome is a complete runtime under `zsh/`. Its contents can be
sourced via `ZDOTDIR` independently of the repository's development files. Tests
and tooling remain in the same source history as the runtime they describe.
The existing distinction between the development checkout and live
configuration remains intact.

## Scope

The repository migration includes moving runtime files, adapting test and
tooling paths, correcting file headers, documenting installation, and proving
that the relocated runtime behaves as before.

The live installation has a separate cutover because its clone and Git
settings are machine-local. This specification defines the conditions for
that cutover so the source change cannot be deployed safely by assumption.
Actual modifications outside this repository belong to a later installation
task.

The following are outside this migration:

- Redesigning the `env/`, `rc/`, `util/`, `func/`, `wrap/`, `comp/`, or `spec/`
  responsibilities or their loading sequence.
- Changing plugin management, pinning plugin revisions, or moving XDG state.
- Replacing the test runner, package manager, hooks, or CI platform.
- Publishing a generated branch, release archive, or new installation tool.
- Changing the location or load precedence of machine-specific environment
  settings beyond preserving the existing generated file.
- Fixing unrelated runtime defects or changing wrapper behaviour.

## Architectural Decision

Use one authoritative repository tree with a dedicated `zsh/` runtime
directory. The alternatives considered were a manually maintained runtime
branch, a generated deployment branch, sparse checkout, a separate tooling
repository, and runtime archives.

A subdirectory keeps configuration changes and their tests together while
making runtime contents explicit. A manually maintained branch would require
ongoing coordination between different layouts. A generated branch or archive
could serve distribution later, but no such requirement currently justifies
the extra publication process. Sparse checkout remains an optional checkout
policy and is not part of the source architecture.

The [assessment](./../notes/2026-11-03_repository-layout-assessment.md#alternatives-and-their-costs)
records the trade-offs in more detail.

## Directory and Ownership Boundaries

```text
repository root/
├── zsh/                   Effective Configuration
│   ├── .zshenv
│   ├── .zshrc
│   ├── env/               Universal Initialisation
│   ├── rc/                Interactive Initialisation
│   ├── util/              Tool-Specific Integration
│   ├── func/              Function (not including wrappers)
│   ├── wrap/              Wrapper
│   ├── comp/              Completion
│   └── spec/              Plugin Specifications
├── tests/                 Runtime and Source-Contract Tests
├── docs/
│   ├── notes/             Rationale and Retained Assessments
│   └── spec/              Architectural Specifications
├── .github/
├── .husky/
├── .claude/
├── AGENTS.md
├── LICENSE
└── Project configuration, dependency manifests, etc.
```

All existing tracked runtime files move beneath `zsh/`, including the startup
files and `comp/.keep`. The root startup files are removed as part of that
move; no repository-root compatibility loader is introduced. Installation
must point zsh at the runtime directory explicitly.

Project files such as `.mise.toml`, `.shuck.toml`, `.nvim.lua`, `package.json`,
and `bun.lock` stay at the repository root. Test binaries, dependency trees,
and generated test reports retain their existing repository-side locations.
No build step is added to produce the runtime.

The runtime may use its existing external tools, plugin cache, and generated
integrations. Independence from repository scaffolding does not mean that it
has no external dependencies.

## Runtime Interface and Invariants

`ZDOTDIR` names the directory containing `.zshenv`, `.zshrc`, and the seven
runtime module directories. In a development checkout that directory is
`<repository>/zsh`; in the preferred live installation it is reached through
the stable configuration path described below.

The source paths in `zsh_dirs` continue to be derived directly from
`ZDOTDIR`. Runtime code must not append another `zsh` component, search for
the Git root, or source files from a parent directory. The XDG defaults and
the fallback configuration path remain unchanged.

The migration preserves these observable properties:

1. `.zshenv` loads `env/*.env.zsh` in the existing alphabetical order and
   emits no stdout bytes, including on a cold start.
2. `.zshrc` remains interactive-only. It loads `ls_colors`, `completion`,
   and `function` first, followed by other rc modules and then utilities.
3. Each rc file retains its nested anonymous-function scope, so existing
   top-level `local` declarations continue to work.
4. Directory globs retain their null-glob qualifiers and file-selection
   restrictions. Reordering patterns remain anchored to final components.
5. `zsh_dirs_require` remains the shared validator. Source keys follow
   `ZDOTDIR`; cache, data, and state keys remain outside it.
6. Completion retains `comp/` precedence, the global compinit opt-out,
   insecure-directory handling, and cache regeneration behaviour.
7. Plugin specs and entry points retain their existing enablement,
   installation, staging, and diagnostic behaviour.
8. Expected first-start directory and cache diagnostics remain on stderr.
   Warm starts retain the existing clean-stream expectations.

Use the existing failure and diagnostic behaviour when configuration is
missing or invalid. The relocation must not introduce silent fallback to the
development checkout or a second configuration tree.

## Test Infrastructure Contract

The support helpers distinguish two global paths:

| Name              | Meaning                                                 | Consumers                                                          |
| ----------------- | ------------------------------------------------------- | ------------------------------------------------------------------ |
| `ZSH_REPO_ROOT`   | Repository root, derived from the helper's own location | Test discovery, repository-relative headers, project tooling trust |
| `ZSH_CONFIG_ROOT` | `$ZSH_REPO_ROOT/zsh`                                    | Runtime file discovery, autoload paths, sandbox links and copies   |

Both existing helpers that establish roots must agree on these definitions.
Their derivation must remain independent of the invoking working directory.
The definitions can remain small assignments in those helpers; this change
does not require introducing a new support subsystem.

`sandbox_create` links `ZSH_CONFIG_ROOT` into the scratch configuration
location. `sandbox_copy_config` copies runtime contents from the same root.
Neither operation installs the repository root as the shell's configuration.

The existing isolated `HOME` and XDG environment, per-entry plugin links,
explicit plugin-cache override, permissions, teardown checks, and first-start
warming remain in force. `MISE_TRUSTED_CONFIG_PATHS`, when used by the test
environment, refers to `ZSH_REPO_ROOT`, because that is where `.mise.toml`
continues to live. Test setup does not export these values into later tests.

Header tests discover runtime shell files beneath `ZSH_CONFIG_ROOT` and test
sources beneath `ZSH_REPO_ROOT`. They compare every header against its path
relative to `ZSH_REPO_ROOT`. For example, the moved loader's header names
`zsh/rc/completion.rc.zsh`, while a support helper still names
`tests/_support/sandbox.zsh`.

Add a deployment-shaped fixture that copies only tracked runtime files into
an isolated installation. It must not link back to the source checkout or
include the generated local environment file. Borrowed plugin clones remain
separate, read-only test inputs under the existing cache rules. Assert the
runtime's source paths and completion/function availability as well as shell
exit status, so a successful shell that loaded nothing cannot pass.

## Project Tooling and Path Migration

The implementation must audit these known path consumers:

| Consumer                               | Required adaptation                                                                                                                         |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `.mise.toml`                           | Prefix runtime syntax-check paths with `zsh/`; retain test support paths and repository task working directory                              |
| `.shuck.toml`                          | Map moved runtime files to zsh; preserve the separate test support mapping and `.zunit` exclusion                                           |
| Test support and suites                | Apply the two-root contract to autoloading, sandbox copying, completion timestamps, discovery, and headers                                  |
| `.github/workflows/lint.yaml`          | Change plugin-cache hash inputs to the relocated spec and completion paths; preserve the provisioned plugin set                             |
| `.nvim.lua`                            | Match new runtime paths for filetypes, body templates, and snippets                                                                         |
| External Neovim configuration          | Verify that source-directory matching still gives moved files `#!/bin/false`; update it only if its current matching requires it            |
| `.gitignore`                           | Move the generated environment-file rule to `/zsh/env/chezmoi.env.zsh`                                                                      |
| `.worktreeinclude`                     | Audit path-sensitive patterns against their intended ignored files; do not copy machine-generated environment settings into a test checkout |
| `.prettierignore` and `.gitattributes` | Check existing patterns against the moved tree and adjust only those whose meaning changes                                                  |
| Runtime headers and documentation      | Update repository-relative paths, installation instructions, links, and the architectural description in `AGENTS.md`                        |

The `~zsh` named-directory shortcut currently prefers the development
repository when it exists. Preserve that navigation behaviour; it must not
become an implicit mechanism for selecting the runtime.

## Live Installation Contract

The preferred installation retains a separate live clone. Its default
location is `${XDG_DATA_HOME:-$HOME/.local/share}/zsh-config`, with the
configuration path `${XDG_CONFIG_HOME:-$HOME/.config}/zsh` pointing to that
clone's `zsh/` directory.

```text
development checkout: ~/dev/zsh-config/
live checkout:        ~/.local/share/zsh-config/
configuration path:   ~/.config/zsh -> ~/.local/share/zsh-config/zsh
ZDOTDIR:              ~/.config/zsh
```

The symlink target must resolve to the actual live runtime directory. The
diagram's locations describe the default XDG case; a real installation must
resolve its configured XDG paths rather than assume these defaults.

The development checkout's `local` remote points to the live repository root,
not its `zsh/` subdirectory. The live repository retains
`receive.denyCurrentBranch=updateInstead`. After migration, the established
process remains: merge through a pull request, pull `main` in the development
checkout to include metadata updates, then push `main` to `local`.

Only the `zsh/` child is presented through the configuration path. The live
clone can contain the full tracked repository; avoiding those files on disk
is not an acceptance requirement. Do not install development dependencies in
the live clone merely to start a shell.

## Portable Startup and Generated Environment

An installation where `ZDOTDIR` is not supplied by the environment must
provide a user-level startup entry. For the existing default configuration
path, a `~/.zshenv` symlink to the installed runtime's `.zshenv` is compatible
with its current XDG fallback. An installation at a custom path must instead
arrange `ZDOTDIR` before sourcing that startup file.

Do not rely on this machine's `/etc/zsh/zshenv` to make the installation
discoverable. Zsh reads the home startup file when `ZDOTDIR` is unset; the
installation contract follows the [documented startup behaviour](https://zsh.sourceforge.io/Doc/Release/Files.html).

The dotfiles repository remains the owner of `chezmoi.env.zsh`. Its effective
output path remains `<configuration path>/env/chezmoi.env.zsh`, which resolves
to `zsh/env/chezmoi.env.zsh` within the live checkout after the move. Preserve
its contents and existing alphabetical loading position.

Inspect the generator during the installation task. If it writes through the
stable configuration path, that destination remains usable; if it names the
old clone location directly or replaces directories, adapt it before cutover.
The generated file must remain untracked. No test fixture may import the live
file's machine-specific values. Continue to run the suite in the development
checkout, never in the live clone.

## Initial Cutover and Recovery

The first deployment cannot use the ordinary push sequence while the old
clone remains the active configuration root. The reorganised commit removes
the startup files from that clone's root.

The installation task must perform the transition in this order:

1. Suspend ordinary pushes to the old live target. Record the active clone's
   revision, local remote configuration, startup-entry arrangement, and local
   generated files. Preserve any existing local changes.
2. After the source migration merges, pull `main` in the development checkout
   before preparing deployment, including any header-metadata commit.
3. Prepare a separate live checkout at the new destination from that exact
   revision. Stop on an unexpected existing destination instead of replacing
   it. Configure its receive policy and restore or regenerate its local
   environment file at the new ignored path.
4. Validate the staged runtime with an isolated home and state, then check
   the machine-specific installation inputs separately. Retain a usable
   shell session throughout the transition.
5. Preserve the old configuration directory as a rollback copy and install
   the prepared symlink at the stable configuration path. Replacing a
   non-empty directory with a symlink is a cutover with a possible path gap;
   do not describe it as an atomic in-place replacement.
6. Update the development checkout's `local` remote to the new live repository
   and verify fresh non-interactive and interactive shells through the stable
   configuration path. Check portable startup in the appropriate fixture.
7. Resume routine deployment only after the checks pass. Retain the previous
   live tree and its local inputs until the installation is accepted.

If validation fails before switching the configuration path, the old live
installation remains active. If it fails after switching, restore the old
configuration directory or pointer, startup entry, and local remote target.
Retain the staged checkout for diagnosis. Recovery must not reset unrelated
user changes or remove XDG cache, data, or state trees.

## Acceptance Criteria

These criteria apply to the future implementation. The normal checks run for
this documentation commit do not demonstrate that the migration satisfies
them.

| ID  | Required evidence                                                                                                                                                                                              |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A1  | All tracked startup and module files live beneath `zsh/`; no root startup shim or runtime dependency on a repository parent remains                                                                            |
| A2  | `mise run lint` and `mise run test` pass from the source checkout; CI's interactive startup tests run with a provisioned plugin cache rather than being skipped                                                |
| A3  | Explicit `ZDOTDIR` selects the relocated runtime from a directory whose name contains spaces or loader keywords, without duplicated sourcing or empty `fpath` elements                                         |
| A4  | A copied installation containing only tracked runtime files starts correctly with isolated XDG state and the expected plugin inputs; assertions prove that the intended modules and autoload paths were loaded |
| A5  | Cold and warm non-interactive starts emit zero stdout bytes; warmed interactive starts meet the existing stream checks; cold completion still handles insecure system paths                                    |
| A6  | A fixture with no inherited XDG variables exercises their defaults, and a portable-startup fixture discovers the installed runtime without a global `ZDOTDIR` assignment                                       |
| A7  | Header tests cover moved runtime files and unmoved test files, using repository-relative paths; Neovim template and header probes work under the new runtime paths                                             |
| A8  | Tests neither clone missing plugins into the live cache nor load real generated `chezmoi.env.zsh` values; the generated file remains ignored at its new repository path                                        |
| A9  | CI cache inputs and all required tooling recognise the new paths; startup does not require Bun, test binaries, or development dependencies solely because of this relocation                                   |
| A10 | Before live activation, the installation task records the deployed source revision, validates the new destination and pointer, verifies the external generator, and demonstrates a recoverable cutover         |

Use the existing sandbox where it expresses these properties. New regression
assertions must be observed failing when their guarded condition is broken,
as required by `AGENTS.md`. Preserve conditional skips for unavailable
subjects, but do not let missing plugin provisioning conceal acceptance of
the interactive migration.

The editor checks remain separate from the aggregate gate: run the documented
Lua checks with the required runtime environment and probe template expansion
in a headless Neovim instance against a new file beneath `zsh/`.

## Review and Implementation Boundary

The proposed source layout and interfaces are specific enough for a later
implementation plan. Machine-local state must be inspected when preparing the
installation task; the default paths above are not evidence that those
locations are currently available.

Review this specification before planning the migration. Keep the source
relocation and its path adaptations together as a behaviour-preserving change,
then perform the separately coordinated live cutover. Any later redesign of
local environment loading or runtime distribution should have its own scope
and acceptance criteria.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
