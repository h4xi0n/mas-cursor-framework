# MAS Cursor Framework

**Version:** 1.1.0 (MAS-01)

Portable distribution of the **Multi-Agent System (MAS)** for [Cursor](https://cursor.com). MAS orchestrates specialized AI agents through slash commands — `/mas` for the full pipeline and `/mas-lite` for token-efficient workflows.

This repo contains everything needed to install MAS on another machine: skills, commands, rules, hooks, and install scripts. It does **not** include per-project `.ai/context/` — that is created separately in each workspace via `init-mas-context.ps1`.

## Repository structure

| Path | Contents |
|------|----------|
| `skills/` | MAS skill trees (`multi-agent-system`, coordinator, specialists, `mas-debate`, `mas-token-auditor`, `mas-lite`) |
| `commands/` | `mas.md`, `mas-lite.md` slash command definitions |
| `rules/` | `multi-agent-hybrid.mdc` workspace rule |
| `hooks/` | Session context hooks (`mas-session-context.ps1`, `.sh`) |
| `install/` | **Pointer only** — see canonical install below |
| `hooks.mas.template.json` | Hook template merged into `~/.cursor/hooks.json` on install |
| `USER-RULE-MAS.md` | Optional global user rule reference |

**Canonical install (edit here only):** `skills/multi-agent-system/install/` — manifest, export/install scripts, `Test-InstallParity` hash guard. Root `install/README.md` redirects to this path. Export copies canonical install into release bundles.

## MAS-01 protocol additions

| File | Purpose |
|------|---------|
| `protocol/spawn-model-policy.md` | Agent slug → `MODEL_CLASS` → Task `model` |
| `protocol/brief-schemas.md` | Required brief sections per artifact type |
| `protocol/token-rules.md` | Chain caps, artifact-forward rule |
| `protocol/read-order.md` | Brief subscription matrix |
| `skills/mas-debate/` | Debate synthesizer on 2nd Reviewer rejection |
| `skills/mas-token-auditor/` | Post-finalize advisory token audit |

Context dirs: `.ai/context/debates/`, `.ai/context/audits/`.

## Quick install

### Windows (double-click)

1. Clone or unzip this repo.
2. Run `skills\multi-agent-system\install\install.bat`.
3. Reload Cursor (**Ctrl+Shift+P** → **Developer: Reload Window**).

### Windows (PowerShell)

```powershell
cd path\to\mas-cursor-framework\skills\multi-agent-system\install
.\install-mas-framework.ps1
```

### macOS / Linux

```bash
cd path/to/mas-cursor-framework/skills/multi-agent-system/install
chmod +x install-mas-framework.sh
./install-mas-framework.sh
```

For detailed transfer steps, Mac notes, and project bootstrap, see [skills/multi-agent-system/install/README.md](skills/multi-agent-system/install/README.md).

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

`Test-InstallParity` fails if root `install/` duplicate scripts drift from canonical.

## Verify installation

1. Open Cursor Agent chat and type `/` — confirm **mas** and **mas-lite** appear.
2. In a project with `.ai/context/`, session hints should mention `/mas` and `/mas-lite`.
3. Run `/mas-lite S` on a small task or `/mas` for the full coordinator pipeline.

## Bootstrap a project

After global install, initialize per-project MAS context:

```powershell
~/.cursor/skills/multi-agent-system/scripts/init-mas-context.ps1 -ProjectPath "C:\path\to\your\project" -Stack auto
```

## Publish to GitHub

```bash
cd mas-cursor-framework
git init
git add .
git commit -m "feat: package MAS Cursor framework v1.1.0"
git remote add origin https://github.com/<you>/mas-cursor-framework.git
git branch -M main
git push -u origin main
```

## License

License TBD — add your chosen license before public release.
