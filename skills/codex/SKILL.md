---
name: codex
description: Invoke Codex CLI (gpt-5.3-codex model) for high-reasoning tasks. Use when user mentions "Codex", requests design/architecture, code review, debug analysis, or algorithm design. Codex = Brain (thinking), Claude = Hands (implementation). Supports session continuation for long-term projects.
---

# Codex CLI Integration (v0.101.0+)

## Critical Rules

1. **Always use `codex exec`** — `codex` (interactive) fails in Claude Code. Exception: `codex review` is already non-interactive
2. **Always add `-c hide_agent_reasoning=true`** — hides thinking output to reduce context consumption
3. **Multi-line prompts must use heredoc** — never use unescaped newlines in quotes, never add `-` after `--last`

## Default Command

```bash
codex exec -m gpt-5.3-codex -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "prompt"
```

Default to **read-only** — Codex thinks, Claude implements. Use `-s workspace-write` only when user explicitly asks Codex to modify files.

## Code Review

```bash
codex review --uncommitted              # Staged, unstaged, and untracked changes
codex review --base main                # Changes against base branch
codex review --commit HEAD~3            # Changes from a specific commit
codex review "Check for security issues"  # Custom instructions
```

## Session Continuation

Sessions persist across Claude Code restarts. Detect continuation when user says "continue", "resume", "keep going", "add to that", or references previous Codex work.

**Resume**:
```bash
codex exec -m gpt-5.3-codex -c hide_agent_reasoning=true resume --last "prompt"
```

**Resume with multi-line**:
```bash
codex exec -m gpt-5.3-codex -c hide_agent_reasoning=true resume --last <<'EOF'
Multi-line prompt here
EOF
```

Key constraints:
- `-m` must match original session's model, placed **before** `resume`
- `--last` resumes the globally most recent session (not per-instance)
- New/fresh requests → omit `resume --last`

## Common Errors

| Error | Fix |
|-------|-----|
| No prompt provided | Add prompt after `resume --last` |
| `--last` conflicts with `SESSION_ID` | Don't add `-` after `--last`; use heredoc for multi-line |
| stdout is not a terminal | Use `codex exec`, not `codex` |
| Not authenticated | Run `codex login` |

## Reference Docs

- `references/codex-help.md` — Full CLI flags and commands
- `references/command-patterns.md` — Workflow examples
- `references/session-workflows.md` — Session continuation details
- `references/troubleshooting.md` — Error solutions
- `references/codex-config.md` — Configuration reference
