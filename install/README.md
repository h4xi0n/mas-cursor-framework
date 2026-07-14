# MAS Framework — Transfer & Install

## Simplest method (3 steps)

1. **On this PC** — run export once (or zip the folder `mas-cursor-framework` after export):
   ```powershell
   cd $env:USERPROFILE\.cursor\skills\multi-agent-system\install
   .\export-mas-framework.ps1
   ```
2. **Copy** `mas-cursor-framework.zip` to the other computer (USB, Google Drive, email, etc.).
3. **On the other PC** — unzip, open the `mas-cursor-framework` folder, **double-click `install.bat`** (Windows).

   Or manually: copy the folders `skills`, `commands`, `rules`, `hooks` from inside the zip into:
   - Windows: `C:\Users\<you>\.cursor\`
   - Mac: `~/.cursor/`

Then **reload Cursor**. Type `/mas` in chat. Done.

No terminal required on the new PC if you use drag-and-drop or `install.bat`.

---

## Other methods

Move the Multi-Agent System (MAS) to another PC or Mac: **export a zip on the source machine**, copy it, **run the installer on the target**.

## Quick start (scripts)

### On this machine (export)

**Windows (PowerShell):**

```powershell
cd $env:USERPROFILE\.cursor\skills\multi-agent-system\install
.\export-mas-framework.ps1
```

Creates: `%USERPROFILE%\Desktop\mas-cursor-framework.zip` (or `-OutputPath`).

**Folder export (no zip):**

```powershell
.\export-mas-framework.ps1 -OutputDir "C:\Users\arunk\AndroidStudioProjects\mas-cursor-framework"
```

**Folder + zip:**

```powershell
.\export-mas-framework.ps1 -OutputDir "C:\dev\out" -OutputPath "C:\dev\mas.zip"
```

| `-OutputDir` | `-OutputPath` | Result |
|--------------|---------------|--------|
| unset | unset | Zip to Desktop |
| set | unset | Folder only |
| unset | set | Zip only |
| set | set | Folder and zip |

### On the new machine (install)

**Windows:**

```powershell
# Unzip mas-cursor-framework.zip anywhere, then:
cd path\to\mas-cursor-framework\install
.\install-mas-framework.ps1
```

**Mac / Linux:**

```bash
cd path/to/mas-cursor-framework/install
chmod +x install-mas-framework.sh
./install-mas-framework.sh
```

Reload Cursor: **Ctrl+Shift+P** / **Cmd+Shift+P** → **Developer: Reload Window**.

### Bootstrap a project (after install)

**Windows:**

```powershell
~/.cursor/skills/multi-agent-system/scripts/init-mas-context.ps1 -ProjectPath "C:\path\to\your\project" -Stack auto
```

**Mac** (PowerShell Core if installed):

```bash
pwsh ~/.cursor/skills/multi-agent-system/scripts/init-mas-context.ps1 -ProjectPath ~/dev/myapp -Stack auto
```

Or copy `.ai/context/` templates manually from `templates/` (see init script).

---

## What gets installed (global Cursor user folder)

| Target | Contents |
|--------|----------|
| `~/.cursor/skills/` | `multi-agent-system`, `mas`, `mas-coordinator`, `mas-planner`, `mas-architect`, `mas-android-dev`, `mas-general-dev`, `mas-bug-fix`, `mas-reviewer`, `mas-documenter`, `mas-spec-reader`, `mas-commit`, `mas-lite` |
| `~/.cursor/commands/` | `mas.md`, `mas-lite.md` |
| `~/.cursor/rules/` | `multi-agent-hybrid.mdc` |
| `~/.cursor/hooks/` | `mas-session-context.ps1` (+ `.sh` on Mac) |
| `~/.cursor/hooks.json` | MAS `sessionStart` + `subagentStop` entries (merged if file exists) |
| `~/.cursor/USER-RULE-MAS.md` | Optional paste reference for User Rules |

**Per project** (not in zip — created per repo):

| Path | Purpose |
|------|---------|
| `.ai/context/project.md` | Stack, modules |
| `.ai/context/coding_standards.md` | Conventions |
| `.ai/context/memory.md` | Durable decisions |
| `.ai/context/specs/` | Spec Reader briefs |
| `.ai/handoffs/` | Agent handoffs |
| `AGENTS.md` | Pointer for agents |
| `.gitignore` | Should include `.ai/` |

---

## Manual copy (no script)

Copy these folders/files from **source** `%USERPROFILE%\.cursor` (Mac: `~/.cursor`):

```
skills/multi-agent-system/     (entire tree including install/)
skills/mas/
skills/mas-brainstorm/
skills/mas-coordinator/
skills/mas-planner/
skills/mas-architect/
skills/mas-android-dev/
skills/mas-general-dev/
skills/mas-bug-fix/
skills/mas-reviewer/
skills/mas-documenter/
skills/mas-spec-reader/
skills/mas-commit/
skills/mas-lite/
commands/mas.md
commands/mas-lite.md
rules/multi-agent-hybrid.mdc
hooks/mas-session-context.ps1
hooks/mas-session-context.sh          (after Mac install)
hooks.json                              (merge — see install script)
USER-RULE-MAS.md                        (optional)
```

Merge into target `~/.cursor` with the same paths.

---

## Verify

1. Type `/` in Agent chat → see **mas** and **mas-lite**.
2. Open a project with `.ai/context/` → session hint mentions `/mas` and `/mas-lite`.
3. Run `/mas-lite S` on a small task or `/mas` for full pipeline.

---

## Mac notes

- Hooks use `mas-session-context.sh` (bash). Windows uses `.ps1`.
- Install script sets `hooks.json` commands to bash on Darwin.
- Project init: install [PowerShell](https://learn.microsoft.com/powershell/) (`pwsh`) or run templates manually.

---

## Optional: workspace commands

Copy to project root for team sharing:

```
your-repo/.cursor/commands/mas.md
your-repo/.cursor/commands/mas-lite.md
```

---

## Updating

Re-run `export-mas-framework.ps1` on the updated machine, copy zip, run `install-mas-framework.ps1 -Force` on targets (`-Force` overwrites skills/commands).
