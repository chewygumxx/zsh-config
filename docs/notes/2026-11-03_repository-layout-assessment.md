---
ctime: 2026-11-03
mtime: 2026-11-03
spdx: GPL-3.0-only
title: Repository Layout Assessment
description: >-
  Assessment of separating the effective Zsh configuration from repository
  scaffolding and test infrastructure, including alternatives and deployment
  implications.
tags:
  - zsh
  - architecture
  - repository
  - note
---

<!--
   -
   - ~chewygumxx/zsh-config.git
   - ::: :/docs/notes/2026-11-03_repository-layout-assessment.md
   -
   -->

# Repository Layout Assessment

| Context | Value                                                        |
| ------- | ------------------------------------------------------------ |
| Date    | 2026-11-03                                                   |
| Basis   | Source layout at `0edc44e` and the repository's `AGENTS.md`  |
| Status  | Architectural conjecture preserved for future consideration  |
| Scope   | Source organisation, test boundaries, and live configuration |

This note records the reasoning behind a proposed repository reorganisation.
It preserves the assessment requested in conversation so that a later decision
does not depend on remembering that discussion. Recording the proposal does
not mean that the migration has been implemented or authorised for deployment.

The companion [design specification](../spec/2026-11-03_runtime-directory-separation.md)
turns the preferred approach into requirements and acceptance criteria.

## Recommendation

Move the effective configuration into a dedicated `zsh/` subdirectory. Keep
the runtime, its tests, and the development infrastructure in the same
repository and commit history.

The repository root currently serves as both the development workspace and
`ZDOTDIR`. That arrangement made sense when the configuration dominated the
tree. As tests, workflows, editor support, and agent configuration accumulated,
those two purposes became less comfortable sharing one directory.

A runtime subdirectory gives each purpose a clear place while allowing a shell
change and its regression test to remain one reviewable commit. It also makes
the boundary directly testable: the contents of `zsh/` should work when copied
away from the rest of the repository, given the normal runtime dependencies.

## Proposed Shape

```text
zsh-config/
├── zsh/
│   ├── .zshenv
│   ├── .zshrc
│   ├── env/
│   ├── rc/
│   ├── util/
│   ├── func/
│   ├── wrap/
│   ├── comp/
│   └── spec/
├── tests/
├── docs/
│   ├── notes/
│   └── spec/
├── .github/
├── .husky/
├── .claude/
├── AGENTS.md
├── LICENSE
├── .mise.toml
└── other project configuration
```

`zsh/` describes a directory that can directly become `ZDOTDIR`. `config/`
would also be reasonable; `src/` is less explicit about the absence of a build
step. The name matters less than keeping the entire runtime together,
including both startup files.

Tool configuration should remain at the repository root where its discovery
mechanism expects it. Moving every dotfile into `tooling/` can introduce extra
arguments and working-directory assumptions. A useful separation does not
require every visible item at the root to be a directory.

The existing `env/`, `rc/`, `util/`, `func/`, `wrap/`, `comp/`, and `spec/`
divisions should survive the move. Their loading order and responsibilities
already encode fixes for real startup failures. Reorganising those internals
at the same time would make a structural migration harder to assess.

## Why the Current Runtime Is Suited to This

[env/zsh_dirs.env.zsh](../../env/zsh_dirs.env.zsh) already separates source
locations from state. Source keys follow `ZDOTDIR`; caches, plugin clones,
generated completions, and history use the relevant XDG locations. The proposed
move should preserve this distinction.

Zsh reads its user startup files beneath `ZDOTDIR`, or beneath `HOME` when
`ZDOTDIR` is unset. A repository subdirectory is therefore a suitable startup
directory without introducing a loader that understands Git or the project
toolchain. See the [Zsh startup documentation](https://zsh.sourceforge.io/Doc/Release/Files.html).

This is an inference from the current code, not evidence that the migration
has already been tested. The likely concentration of work is in test helpers,
lint globs, editor integration, file headers, and installation arrangements.

## Alternatives and Their Costs

| Approach                           | Benefit                                                | Cost or limitation                                                   | Assessment                                       |
| ---------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------- | ------------------------------------------------ |
| Runtime subdirectory               | Clear source boundary; tests and runtime share commits | Existing path assumptions must be updated                            | Preferred                                        |
| Manually maintained runtime branch | A clone can expose startup files at its root           | Runtime and test changes require coordination across different trees | Avoid for routine authoring                      |
| Generated deployment branch        | A configuration-only clone remains possible            | Needs generation, provenance, and publication rules                  | Consider for a concrete distribution requirement |
| Sparse checkout                    | Reduces files materialised in a live checkout          | Does not establish the source boundary or relocate selected paths    | Optional deployment detail                       |
| Separate infrastructure repository | Independent ownership and release cadence              | Tests and the configuration they describe can drift                  | Little benefit for the present repository        |
| Runtime archive                    | Installation need not include Git or development files | Requires an explicit update and rollback procedure                   | Possible later distribution mechanism            |

A dedicated branch is most defensible as generated deployment output. The
authoritative changes would still be made alongside their tests, and the
generated branch would receive no independent edits. The runtime revision
would need an explicit association with the source commit that produced it.

Sparse checkout controls which tracked paths appear in a working tree. It
does not move a selected subdirectory to the checkout root, and its default
cone mode includes root-level files. It can complement a runtime directory,
but adds little if a symlink already presents that directory as the live
configuration. See the [Git sparse-checkout documentation](https://git-scm.com/docs/git-sparse-checkout).

Git can archive a selected tree without maintaining a separate branch. Any
runtime distribution would also need the applicable licence material and
source-revision provenance. See the [Git archive documentation](https://git-scm.com/docs/git-archive).

## Source Layout and Live Installation Are Separate Decisions

The development checkout and the live clone currently serve different
purposes. Retaining that separation means branch switches and unfinished
changes in the development checkout do not alter newly started shells.

An illustrative installation is:

```text
~/dev/zsh-config/                    development checkout
~/.local/share/zsh-config/           live checkout
~/.config/zsh -> ~/.local/share/zsh-config/zsh
```

The exact paths are installation policy. In this arrangement, `ZDOTDIR` stays
at `~/.config/zsh`, while the `local` Git remote targets the relocated live
clone. Its `receive.denyCurrentBranch=updateInstead` setting can continue to
serve deliberate updates after changes have merged and `main` has been
pulled in the development checkout.

The first transition needs special handling. Pushing a commit that removes
the root startup files into the current live clone would leave its existing
`ZDOTDIR` without those files. Stage and validate the new live location before
switching the configuration path; do not treat this initial cutover as an
ordinary `git push local main`.

A portable installation must also cover machines where the system does not
provide `ZDOTDIR`. A home-level `.zshenv` bootstrap or suitable symlink should
lead into the installed configuration. The repository must continue to work
without this machine's `/etc/zsh/zshenv` defaults.

## Machine-Specific Inputs Need Their Own Ownership

The generated `env/chezmoi.env.zsh` is an important exception to a purely
tracked runtime tree. The dotfiles repository writes it into the live clone,
and its contents describe machine-specific paths. Moving source files does
not remove this ownership boundary.

Initially, a stable `~/.config/zsh` symlink can preserve the visible output
path used by that generator. The ignore rule must follow the file's new
repository-relative location, and the sandbox must continue to avoid loading
the real machine's generated values.

An explicitly supported external location for local environment settings
could improve separation later. That would change the loading contract and
deserves its own design. It should not be silently folded into the directory
move.

## Migration Work Worth Remembering

- Give test helpers distinct repository-root and runtime-root values. Today
  `ZSH_CONFIG_ROOT` represents both.
- Make the sandbox link or copy the runtime directory, and verify a startup
  with repository scaffolding physically absent from that installation.
- Update syntax and formatting globs, CI plugin-cache inputs, ignore rules,
  editor templates, agent instructions, and repository-relative file headers.
- Preserve the current load order, nested anonymous-function scopes,
  completion precedence, XDG fallbacks, and non-interactive stdout discipline.
- Coordinate the live clone, its local remote, startup discovery, and the
  external generator of `chezmoi.env.zsh` before the first deployment.

The expected payoff is a clearer ownership boundary and a more credible
runtime-only test fixture. It is not a claim of faster startup, fewer runtime
dependencies, or reproducible plugin revisions. Those properties would need
separate changes and evidence.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
