# Multi-Agent User Rule

If the hybrid rule is not active automatically, paste the content below into **Cursor Settings → Rules → User Rules**.

---

# Multi-Agent Context (Hybrid)

**Default:** Do not preload `.ai/context/` unless the task needs project facts.

When `/mas-lite` or `/mas lite`:

- Load skill `mas-lite`; Coordinator Lite Mode; read `memory.md` only at startup
- Tier S/M/L; skip Documenter and full Reviewer

When `/mas` (full slash command), `mas` skill, or explicit Coordinator request:

- Load skill `multi-agent-system` (via `~/.cursor/commands/mas.md` or `mas` skill alias)
- Read: `project.md`, `coding_standards.md`, `memory.md`
- Act ONLY as Coordinator; foreground Task subagents only

Normal chat unchanged unless `/mas` or `/mas-lite`.

---

Also installed at: `~/.cursor/rules/multi-agent-hybrid.mdc`
