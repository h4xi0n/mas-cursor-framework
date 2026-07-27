# MAS Install — Canonical Path

Root `install/` in this repo is **pointer-only**. Do not add install scripts here.

## Edit and run install scripts here

```
skills/multi-agent-system/install/
```

| Script | Purpose |
|--------|---------|
| `export-mas-framework.ps1` | Package bundle / sync workspace clone |
| `install-mas-framework.ps1` | Install to `~/.cursor` (Windows) |
| `install-mas-framework.sh` | Install to `~/.cursor` (macOS/Linux) |
| `install.bat` | Windows double-click installer |
| `manifest.json` | Skills and assets list |

## Quick start

```powershell
cd skills\multi-agent-system\install
.\export-mas-framework.ps1
```

```powershell
.\install-mas-framework.ps1
```

Full transfer guide: [skills/multi-agent-system/install/README.md](../skills/multi-agent-system/install/README.md).

## Why pointer-only?

Canonical install lives beside protocol and skills. `export-mas-framework.ps1` copies canonical `install/` into release bundles. `Test-InstallParity` fails if duplicate root copies drift from canonical.
