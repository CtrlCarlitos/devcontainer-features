# Historical `zsh-plugins` Feature Research

Research date: 2026-09-14. Scope is historical evidence and replacement
viability only; no Feature or workflow was changed.

## Recommendation

**Omit; do not restore or replace this as a first-party Feature.** The exact
two-plugin behavior is already easily expressed in user-owned Zsh
configuration, while the maintained official baseline is
[`common-utils:2`](https://github.com/devcontainers/features/tree/main/src/common-utils).
It installs Zsh and Oh My Zsh by default and exposes documented switches for
both. It deliberately does not own third-party plugin selection.

The only matching public Feature source found is a small, unmaintained
third-party implementation. It is not listed in the Dev Container Feature
catalog and its repository has no GitHub Container Registry package. It is not
a suitable dependency or code source for a maintained Feature.

## Archive Result

The requested private archive is
[`CtrlCarlitos/devcontainer-features-archive`](https://github.com/CtrlCarlitos/devcontainer-features-archive).
Its reachable refs, commits, trees, blobs, branches, tags, pull requests, and
unreachable local Git objects contain **no** `zsh-plugins` path, source,
metadata, test, README, or removal commit. The archive is marked archived; its
reachable history starts with `f582d2a9dfddc3aa368d536f42227c7afbdc898c`
(`Initial commit`, 2026-01-18).

The archive's only comparable removal is unrelated:
[`f5a6332b7e1c09574c0856d0f4f2b5b633d57046`](https://github.com/CtrlCarlitos/devcontainer-features-archive/commit/f5a6332b7e1c09574c0856d0f4f2b5b633d57046),
`remove bmad-method feature (no longer used)`, on 2026-09-13. It removes only
`src/bmad-method/{README.md,devcontainer-feature.json,install.sh}` and
`test/bmad-method/{default.sh,scenarios.json}`. The following README cleanup,
[`2ff5fcfda681a7d001e947fc0df9d91ef36f9bd7`](https://github.com/CtrlCarlitos/devcontainer-features-archive/commit/2ff5fcfda681a7d001e947fc0df9d91ef36f9bd7),
also mentions only `bmad-method`. Therefore there is no archive-backed legacy
artifact to restore and no removal context specific to `zsh-plugins`.

## Likely Public Source

The exact public Feature identifier and behavior are in
[`brucemontegani/devcontainer-features`](https://github.com/brucemontegani/devcontainer-features):

| Fact | Evidence |
| --- | --- |
| Paths | [`src/zsh-plugins/devcontainer-feature.json`](https://github.com/brucemontegani/devcontainer-features/blob/0e6aa0320a5dfed8a55c67bcf9695cb720054305/src/zsh-plugins/devcontainer-feature.json), [`src/zsh-plugins/install.sh`](https://github.com/brucemontegani/devcontainer-features/blob/0e6aa0320a5dfed8a55c67bcf9695cb720054305/src/zsh-plugins/install.sh), and generated [`output/devcontainer-collection.json`](https://github.com/brucemontegani/devcontainer-features/blob/0e6aa0320a5dfed8a55c67bcf9695cb720054305/src/zsh-plugins/output/devcontainer-collection.json) |
| Last Feature commit | [`0e6aa0320a5dfed8a55c67bcf9695cb720054305`](https://github.com/brucemontegani/devcontainer-features/commit/0e6aa0320a5dfed8a55c67bcf9695cb720054305), `Package up zsh-plugins`, 2025-08-04 |
| Earlier Feature commit | [`bf294bed2c3894ff0daba420cf2a03a4a27ac026`](https://github.com/brucemontegani/devcontainer-features/commit/bf294bed2c3894ff0daba420cf2a03a4a27ac026), `Initial commit`, 2025-08-01 |
| Metadata | `id: zsh-plugins`, version `1.0.0`, no options, and `installsAfter: [ghcr.io/devcontainers/features/common-utils]` |
| Tests and README | Neither `src/zsh-plugins/README.md` nor `test/zsh-plugins/` exists in the source tree. |

### Behavior and Dependencies

The installer assumes the Feature runtime supplies `_REMOTE_USER` and
`_REMOTE_USER_HOME`, assumes Oh My Zsh already exists at
`$HOME/.oh-my-zsh`, and requires `git`. It shallow-clones
[`zsh-users/zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions)
and [`zsh-users/zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting)
into Oh My Zsh's custom-plugin directory. It prepends both names to an existing
`plugins=(...)` line, or appends a new line, then changes ownership. Existing
plugin directories are skipped; the `.zshrc` edit itself is not idempotent and
there is no version pinning, checksum, plugin selection, user, or install-path
option. The source is the authoritative record of all of these behaviors.

The public repository was last pushed on 2025-08-04, declares no recognized
license through GitHub's API, and has no GitHub Container Registry package.
Its checked-in tarball is not evidence of a consumable published Feature.

## Current Maintained Choices

* Official [`common-utils:2`](https://github.com/devcontainers/features/tree/main/src/common-utils)
  is the maintained first-party baseline. Its
  [`metadata`](https://raw.githubusercontent.com/devcontainers/features/main/src/common-utils/devcontainer-feature.json)
  defaults `installZsh`, `installOhMyZsh`, and `installOhMyZshConfig` to
  `true`; it also supports setting Zsh as the default shell. Its
  [README](https://github.com/devcontainers/features/blob/main/src/common-utils/README.md)
  documents the options and changing `ZSH_THEME`. It does not provide a
  generic external-plugin option.
* [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) is the framework that owns
  plugin activation. Its [README](https://github.com/ohmyzsh/ohmyzsh/blob/master/README.md)
  documents the `plugins=(...)` setting and bundled-plugin documentation.
* [Antidote](https://antidote.sh/) is a maintained native-Zsh plugin manager
  for users who need declarative third-party plugins, static generated load
  files, pinning, and deferred loading. Its
  [options documentation](https://antidote.sh/options) defines `pin:<SHA>` and
  `kind:defer`; its [usage documentation](https://antidote.sh/) shows loading
  Oh My Zsh subpaths and arbitrary plugins.
* [Zinit](https://github.com/zdharma-continuum/zinit) is an alternative
  manager. Its [official README](https://github.com/zdharma-continuum/zinit/blob/main/README.md)
  documents normal plugin loading, Oh My Zsh snippets, and `wait` Turbo-mode
  deferred loading.
* [`zsh-defer`](https://github.com/romkatv/zsh-defer) is not a plugin manager;
  it only defers Zsh commands. Its
  [README](https://github.com/romkatv/zsh-defer/blob/master/README.md) warns
  that deferred initialization can break plugins and should not be used for
  commands requiring input.

## Public Feature Coverage

The Dev Container catalog lists official `common-utils` but not the public
`brucemontegani` `zsh-plugins` Feature. The latter is functionally a direct
match for the old fixed pair, but it is neither a verified published Feature
reference nor maintained enough to adopt. No public, maintained Feature was
found that safely exposes a generic, pinned Zsh-plugin-management interface.

Use `common-utils:2` for Zsh and Oh My Zsh. Keep any project-specific plugin
list in the project's dotfiles or configure a user-selected manager such as
Antidote or Zinit there. This preserves plugin ownership, permits commit
pinning, and avoids reviving a fixed, untested two-plugin Feature.
