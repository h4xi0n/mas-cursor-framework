# Git Commit Standards

Reference for the Commit agent. **Never commit or push without explicit user confirmation.**

## Analysis Phase (always first)

Run in parallel:

```bash
git status
git diff
git diff --staged
git log -3 --oneline
git branch -vv
```

Understand: what changed, why (from handoff/TASK_ID/reviewer), repo commit message style.

## Commit Message Format

Match existing `git log` style. Default conventional form if none:

```
<type>(<scope>): <short summary>

<optional body — why, not what>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`

- Summary: imperative, ≤72 chars, no period
- Body: 1–3 sentences on **why**
- Reference `TASK_ID` in body when from `/mas` workflow (e.g. `STICKER-01`)

## Files to Stage

- Stage only files related to the completed work
- **Never** stage: `.env`, credentials, `local.properties`, secrets, `.ai/` (gitignored), accidental build artifacts
- Warn user if they request staging sensitive paths

## User Confirmation (mandatory)

Two-step gate — **never skip**:

### Step 1 — Commit

Present to user:

- Proposed commit message (full)
- File list to be staged
- Current branch

Ask explicitly: **"Approve this commit? (yes/no)"**

- **yes** → `git add` + `git commit`
- **no** → revise message or stop; output `COMMIT: SKIPPED`

Do not commit on ambiguous replies ("ok", "looks good") unless user clearly confirms commit.

### Step 2 — Push (separate)

Only after successful commit (or if user only wanted push of existing commits).

Present:

- Branch name
- Remote tracking status (`ahead/behind`)
- Target remote (default `origin`)

Ask: **"Push to remote? (yes/no)"**

- **yes** → `git push -u origin HEAD` if no upstream, else `git push`
- **no** → output `PUSH: SKIPPED`

## Git Safety (never violate)

- NEVER `git push --force` to `main`/`master` — warn user
- NEVER `--no-verify` / skip hooks unless user explicitly requests
- NEVER `git commit --amend` unless user rules allow (amend only if HEAD was agent-created and not pushed)
- NEVER update git config
- NEVER commit unless user confirmed Step 1
- NEVER push unless user confirmed Step 2

## Windows Commit Command

PowerShell:

```powershell
git add <files>
git commit -m "subject line" -m "body paragraph"
```

Or:

```powershell
@"
subject line

body paragraph
"@ | Set-Content -Path .git/COMMIT_MSG_TMP -Encoding utf8
git commit -F .git/COMMIT_MSG_TMP
Remove-Item .git/COMMIT_MSG_TMP
```

## When Reviewer Must Pass First

If handoff from `/mas` workflow with code changes:

- Do not commit unless `Reviewer Approved: YES` **or** user explicitly overrides
- User override must be explicit ("commit without review")

## Empty Changes

If nothing to commit → report cleanly; do not create empty commit.
