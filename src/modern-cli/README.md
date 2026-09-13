# Modern CLI Tools

Installs a curated set of modern CLI tools. Uses apt where the distro
carries the package, and falls back to pinned GitHub release downloads
(x86_64 and aarch64) where it doesn't.

| Tool     | Binary | What it does                                                    |
|----------|--------|-----------------------------------------------------------------|
| bat      | `bat`  | A `cat` clone with syntax highlighting and Git integration      |
| eza      | `eza`  | A modern `ls` replacement with colors, icons, and Git status    |
| fd       | `fd`   | A fast, user-friendly alternative to `find`                     |
| ripgrep  | `rg`   | An extremely fast `grep` that respects .gitignore by default    |
| delta    | `delta`| A syntax-highlighting pager for Git diffs and side-by-side view |
| fzf      | `fzf`  | A command-line fuzzy finder for files, history, anything        |
| jq       | `jq`   | A lightweight JSON processor for the command line               |
| duf      | `duf`  | A better `df` — disk usage overview with a clean table output   |

## Usage

Add to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/CtrlCarlitos/devcontainer-features/modern-cli:1": {}
    }
}
```

## What it does

- Per tool: skips if already installed (idempotent)
- Tries `apt-get install` first (correct package names, e.g. `fd-find` →
  `fdfind`, `git-delta` for delta, `ripgrep` → `rg`)
- Falls back to a pinned GitHub release download (musl static builds where
  available) when apt doesn't carry the package or fails
- Every tool is made reachable at `/usr/local/bin/<name>` so minimal
  devcontainer shells find it
- Verifies all 8 tools at the end and fails the build if any are missing

## Notes

- Debian/Ubuntu bases get apt; other bases get download fallbacks (musl
  builds run anywhere; delta is glibc-only)
- Fallback versions are pinned in `install.sh` for reproducible builds
- No Node.js required
