#!/bin/bash
set -euo pipefail

echo "Modern CLI Tools Feature"

# Pinned fallback versions (used when apt doesn't carry the package)
BAT_VERSION="v0.24.0"
EZA_VERSION="v0.20.16"
FD_VERSION="v10.2.0"
RIPGREP_VERSION="14.1.1"
DELTA_VERSION="0.18.2"
FZF_VERSION="0.56.3"
JQ_VERSION="jq-1.7.1"
DUF_VERSION="v0.8.1"

APT_UPDATED=0

ensure_apt_updated() {
    if [ "$APT_UPDATED" -eq 0 ]; then
        echo "Updating apt package lists..."
        apt-get update -qq || echo "  (apt update failed; relying on download fallbacks)"
        APT_UPDATED=1
    fi
}

# try_apt <package> — install via apt if possible; return 1 on failure
try_apt() {
    command -v apt-get &> /dev/null || return 1
    ensure_apt_updated
    apt-get install -y --no-install-recommends "$1" > /dev/null 2>&1
}

# tool_present <binary> — already installed?
tool_present() {
    [ -x "/usr/local/bin/$1" ] || command -v "$1" &> /dev/null
}

# link_bin <name> <existing-path> — make the tool reachable at /usr/local/bin
link_bin() {
    local name="$1" src="$2"
    if [ -n "$src" ] && [ -e "$src" ] && [ ! -e "/usr/local/bin/$name" ]; then
        ln -sf "$(readlink -f "$src")" "/usr/local/bin/$name"
    fi
}

# install_tarball <url> <binary-name> <dest-name> — download, extract, copy
install_tarball() {
    local url="$1" bin="$2" dest="$3"
    local tmp
    tmp=$(mktemp -d /tmp/modern-cli-XXXXXX)
    curl -fsSL --connect-timeout 15 --max-time 300 -o "$tmp/dl" "$url"
    case "$url" in
        *.tar.gz|*.tgz) tar -xzf "$tmp/dl" -C "$tmp" ;;
    esac
    local found
    found="$(find "$tmp" -type f -name "$bin" | head -n1)"
    if [ -z "$found" ]; then
        rm -rf "$tmp"
        return 1
    fi
    cp "$found" "/usr/local/bin/$dest"
    chmod +x "/usr/local/bin/$dest"
    rm -rf "$tmp"
}

# Architecture-specific asset fragments
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)
        MUSL="x86_64-unknown-linux-musl"
        GNU="x86_64-unknown-linux-gnu"
        FZF_ARCH="amd64"; DUF_ARCH="x86_64"; JQ_ARCH="amd64"
        ;;
    aarch64|arm64)
        MUSL="aarch64-unknown-linux-musl"
        GNU="aarch64-unknown-linux-gnu"
        FZF_ARCH="arm64"; DUF_ARCH="arm64"; JQ_ARCH="arm64"
        ;;
    *)
        MUSL=""; GNU=""
        FZF_ARCH=""; DUF_ARCH=""; JQ_ARCH=""
        echo "WARNING: unsupported arch '$ARCH' — apt-only mode (no download fallbacks)"
        ;;
esac

# --- bat --------------------------------------------------------------------
# Ubuntu's `bat` apt package installs the binary as `batcat` (the `bat`
# name is taken by a different package). After apt install, check both
# names and symlink whichever exists.
if tool_present bat || command -v batcat &> /dev/null; then
    echo "bat: already installed. Skipping."
else
    echo "bat: installing..."
    if try_apt bat; then
        # apt may have installed it as batcat (Ubuntu naming)
        if command -v bat &> /dev/null; then
            link_bin bat "$(command -v bat)"
        elif command -v batcat &> /dev/null; then
            ln -sf "$(readlink -f "$(command -v batcat)")" /usr/local/bin/bat
        fi
        echo "bat: installed via apt"
    elif [ -n "$MUSL" ]; then
        install_tarball \
            "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-${MUSL}.tar.gz" \
            bat bat
        echo "bat: installed from GitHub release ${BAT_VERSION}"
    else
        echo "bat: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# --- eza --------------------------------------------------------------------
if tool_present eza; then
    echo "eza: already installed ($(command -v eza || echo /usr/local/bin/eza)). Skipping."
else
    echo "eza: installing..."
    if try_apt eza; then
        link_bin eza "$(command -v eza || true)"
        echo "eza: installed via apt"
    elif [ -n "$MUSL" ]; then
        install_tarball \
            "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${MUSL}.tar.gz" \
            eza eza
        echo "eza: installed from GitHub release ${EZA_VERSION}"
    else
        echo "eza: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# --- fd (apt package is fd-find, binary is fdfind) --------------------------
if tool_present fd; then
    echo "fd: already installed ($(command -v fd || echo /usr/local/bin/fd)). Skipping."
else
    echo "fd: installing..."
    FD_OK=0
    if try_apt fd-find; then
        FDFIND="$(command -v fdfind || true)"
        if [ -z "$FDFIND" ] && [ -x /usr/bin/fd ]; then
            FDFIND="/usr/bin/fd"
        fi
        if [ -n "$FDFIND" ]; then
            link_bin fd "$FDFIND"
            echo "fd: installed via apt (fd-find)"
            FD_OK=1
        fi
    fi
    if [ "$FD_OK" -eq 0 ]; then
        if [ -n "$MUSL" ]; then
            install_tarball \
                "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-${MUSL}.tar.gz" \
                fd fd
            echo "fd: installed from GitHub release ${FD_VERSION}"
        else
            echo "fd: FAILED (no apt package and no fallback for this arch)"
        fi
    fi
fi

# --- ripgrep (binary: rg) ----------------------------------------------------
if tool_present rg; then
    echo "ripgrep: already installed ($(command -v rg || echo /usr/local/bin/rg)). Skipping."
else
    echo "ripgrep: installing..."
    if try_apt ripgrep; then
        link_bin rg "$(command -v rg || true)"
        echo "ripgrep: installed via apt"
    elif [ -n "$MUSL" ]; then
        install_tarball \
            "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${MUSL}.tar.gz" \
            rg rg
        echo "ripgrep: installed from GitHub release ${RIPGREP_VERSION}"
    else
        echo "ripgrep: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# --- delta -------------------------------------------------------------------
if tool_present delta; then
    echo "delta: already installed ($(command -v delta || echo /usr/local/bin/delta)). Skipping."
else
    echo "delta: installing..."
    if try_apt git-delta; then
        link_bin delta "$(command -v delta || true)"
        echo "delta: installed via apt (git-delta)"
    elif [ -n "$GNU" ]; then
        install_tarball \
            "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-${GNU}.tar.gz" \
            delta delta
        echo "delta: installed from GitHub release ${DELTA_VERSION}"
    else
        echo "delta: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# --- fzf ---------------------------------------------------------------------
if tool_present fzf; then
    echo "fzf: already installed ($(command -v fzf || echo /usr/local/bin/fzf)). Skipping."
else
    echo "fzf: installing..."
    if try_apt fzf; then
        link_bin fzf "$(command -v fzf || true)"
        echo "fzf: installed via apt"
    elif [ -n "$FZF_ARCH" ]; then
        install_tarball \
            "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${FZF_ARCH}.tar.gz" \
            fzf fzf
        echo "fzf: installed from GitHub release ${FZF_VERSION}"
    else
        echo "fzf: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# --- jq ----------------------------------------------------------------------
if tool_present jq; then
    echo "jq: already installed ($(command -v jq || echo /usr/local/bin/jq)). Skipping."
else
    echo "jq: installing..."
    if try_apt jq; then
        link_bin jq "$(command -v jq || true)"
        echo "jq: installed via apt"
    elif [ -n "$JQ_ARCH" ]; then
        curl -fsSL --connect-timeout 15 --max-time 300 \
            -o /usr/local/bin/jq \
            "https://github.com/jqlang/jq/releases/download/${JQ_VERSION}/jq-linux-${JQ_ARCH}"
        chmod +x /usr/local/bin/jq
        echo "jq: installed from GitHub release ${JQ_VERSION}"
    else
        echo "jq: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# --- duf ---------------------------------------------------------------------
if tool_present duf; then
    echo "duf: already installed ($(command -v duf || echo /usr/local/bin/duf)). Skipping."
else
    echo "duf: installing..."
    if try_apt duf; then
        link_bin duf "$(command -v duf || true)"
        echo "duf: installed via apt"
    elif [ -n "$DUF_ARCH" ]; then
        install_tarball \
            "https://github.com/muesli/duf/releases/download/${DUF_VERSION}/duf_${DUF_VERSION#v}_linux_${DUF_ARCH}.tar.gz" \
            duf duf
        echo "duf: installed from GitHub release ${DUF_VERSION}"
    else
        echo "duf: FAILED (no apt package and no fallback for this arch)"
    fi
fi

# Final verification — the test depends on this
echo ""
echo "Verifying installations..."
FAILED=0
for tool in bat eza fd rg delta fzf jq duf; do
    if [ -x "/usr/local/bin/$tool" ] || command -v "$tool" &> /dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool MISSING"
        FAILED=1
    fi
done

if [ "$FAILED" -ne 0 ]; then
    echo "ERROR: some tools failed to install."
    exit 1
fi

echo "All modern CLI tools installed successfully!"
