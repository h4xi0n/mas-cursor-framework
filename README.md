# MAS Cursor Framework

**Version:** 1.0.0

Portable distribution of the **Multi-Agent System (MAS)** for [Cursor](https://cursor.com). MAS orchestrates specialized AI agents through slash commands — `/mas` for the full pipeline and `/mas-lite` for token-efficient workflows.

This repo contains everything needed to install MAS on another machine: skills, commands, rules, hooks, and install scripts. It does **not** include per-project `.ai/context/` — that is created separately in each workspace via `init-mas-context.ps1`.

## Repository structure

| Path | Contents |
|------|----------|
| `skills/` | 20 MAS skill trees (`multi-agent-system`, coordinator, specialists, `mas-lite`) |
| `commands/` | `mas.md`, `mas-lite.md` slash command definitions |
| `rules/` | `multi-agent-hybrid.mdc` workspace rule |
| `hooks/` | Session context hooks (`mas-session-context.ps1`, `.sh`) |
| `install/` | Manifest, export/install scripts, `install.bat` |
| `hooks.mas.template.json` | Hook template merged into `~/.cursor/hooks.json` on install |
| `USER-RULE-MAS.md` | Optional global user rule reference |

Nested `skills/multi-agent-system/install/` mirrors root `install/` by design (see [install/README.md](install/README.md)).

## Quick install

### Windows (double-click)

1. Clone or unzip this repo.
2. Double-click `install/install.bat`.
3. Reload Cursor (**Ctrl+Shift+P** → **Developer: Reload Window**).

### Windows (PowerShell)

```powershell
cd path\to\mas-cursor-framework\install
.\install-mas-framework.ps1
```

### macOS / Linux

```bash
cd path/to/mas-cursor-framework/install
chmod +x install-mas-framework.sh
./install-mas-framework.sh
```

For detailed transfer steps, Mac notes, and project bootstrap, see [install/README.md](install/README.md).

## Export from source

To refresh this bundle from a live `~/.cursor` install:

```powershell
cd $env:USERPROFILE\.cursor\skills\multi-agent-system\install
.\export-mas-framework.ps1
```

| Flags | Result |
|-------|--------|
| *(none)* | Zip to Desktop |
| `-OutputPath "D:\backups\mas.zip"` | Zip only |
| `-OutputDir "C:\dev\mas-cursor-framework"` | Folder only |
| Both `-OutputDir` and `-OutputPath` | Folder and zip |

Example — sync into a workspace clone:

```powershell
.\export-mas-framework.ps1 -SourceCursorHome "$env:USERPROFILE\.cursor" -OutputDir "C:\path\to\mas-cursor-framework"
```

## Verify installation

1. Open Cursor Agent chat and type `/` — confirm **mas** and **mas-lite** appear.
2. In a project with `.ai/context/`, session hints should mention `/mas` and `/mas-lite`.
3. Run `/mas-lite S` on a small task or `/mas` for the full coordinator pipeline.

## Bootstrap a project

After global install, initialize per-project MAS context:

```powershell
~/.cursor/skills/multi-agent-system/scripts/init-mas-context.ps1 -ProjectPath "C:\path\to\your\project" -Stack auto
```

## License

License TBD — add your chosen license before public release.
