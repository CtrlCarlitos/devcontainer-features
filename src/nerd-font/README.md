
# Nerd Font (nerd-font)

Installs Nerd Fonts (e.g. Meslo, FiraCode) and updates font cache.

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/nerd-font:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| fonts | Comma-separated list of fonts to install (e.g. 'Meslo,FiraCode,JetBrainsMono'). Must match the Nerd Fonts release zip filenames. | string | Meslo |
| version | Version of Nerd Fonts to install (e.g. '3.4.0', '3.1.1') | string | latest |

# Additional Notes for Nerd Font Feature

## Popular Fonts

The following fonts are commonly used and tested with this feature:

| Font Name | Description | Use Case |
|-----------|-------------|----------|
| `Meslo` | Default. Clean, readable monospace font | General terminal use |
| `FiraCode` | Ligatures for programming operators | Code editors, IDEs |
| `JetBrainsMono` | JetBrains' developer font with ligatures | JetBrains IDEs, VS Code |
| `Hack` | Optimized for source code | Terminal, editors |
| `CascadiaCode` | Microsoft's developer font | Windows Terminal, VS Code |
| `SourceCodePro` | Adobe's monospace font | Cross-platform development |
| `UbuntuMono` | Ubuntu's monospace font | Ubuntu-themed setups |

> **Tip**: Font names must match the Nerd Fonts release zip filenames exactly.  
> See the [Nerd Fonts Releases](https://github.com/ryanoasis/nerd-fonts/releases) page for the complete list.

## Example Configurations

### Single Font (Default)
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/nerd-font:1": {}
}
```

### Multiple Fonts
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/nerd-font:1": {
        "fonts": "FiraCode,JetBrainsMono,Hack"
    }
}
```

### Specific Version
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/nerd-font:1": {
        "fonts": "Meslo",
        "version": "3.3.0"
    }
}
```

### Latest Version
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/nerd-font:1": {
        "version": "latest"
    }
}
```

## Terminal Configuration

After installing Nerd Fonts, configure your terminal to use them:

### VS Code (settings.json)
```json
{
    "terminal.integrated.fontFamily": "'MesloLGS NF', 'FiraCode Nerd Font', monospace"
}
```

### Windows Terminal (settings.json)
```json
{
    "profiles": {
        "defaults": {
            "font": {
                "face": "MesloLGS NF"
            }
        }
    }
}
```

### iTerm2 (macOS)
1. Open Preferences → Profiles → Text
2. Click "Change Font"
3. Select your installed Nerd Font (e.g., "MesloLGS NF")

## Troubleshooting

### Font not showing in terminal
1. Verify the font is installed: `fc-list | grep -i "meslo"`
2. Refresh font cache: `fc-cache -f -v`
3. Restart your terminal application

### Download fails
- Check your internet connection
- Verify the font name matches exactly (case-sensitive)
- Try using a specific version instead of `latest`
- Check if GitHub API rate limiting is affecting the download

### Icons not displaying
- Ensure your terminal emulator supports Unicode
- Try a different Nerd Font variant
- Some terminal themes may override icon colors

## Supported Base Images

This feature requires `apt-get` and works with:
- Debian-based images (Ubuntu, Debian)
- Microsoft's devcontainer base images (`mcr.microsoft.com/devcontainers/base:ubuntu`)

Alpine and other non-Debian distributions are **not currently supported**.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
