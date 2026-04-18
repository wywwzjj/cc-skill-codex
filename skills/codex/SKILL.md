---
name: codex
description: Invoke Codex CLI (`gpt-5.4` by default) for high-reasoning tasks. Use when user mentions "Codex", requests design/architecture, code review, debug analysis, or algorithm design. Codex = Brain (thinking), Claude = Hands (implementation). Supports session continuation for long-term projects.
---

# Codex CLI Integration (v0.114.0+)

## Critical Rules

1. **Always use `codex exec`** — `codex` (interactive) fails in Claude Code
2. **Always add `-c hide_agent_reasoning=true`** — hides thinking output to reduce context consumption
3. **Always redirect stderr to `/tmp/codex_stderr.log`** — intermediate process output (session info, tool calls, token stats) goes to stderr; redirect to a fixed temp file to avoid filling context while keeping it accessible for debugging
4. **Multi-line prompts must use heredoc** — never use unescaped newlines in quotes, never add `-` after `--last`
5. **New sessions default to `gpt-5.4` with high reasoning** — resumed sessions inherit the original session settings unless you override them

## Default Command

```bash
codex exec -m gpt-5.4 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "prompt" 2>/tmp/codex_stderr.log
```

Default to **read-only** — Codex thinks, Claude implements. Use `-s workspace-write` only when user explicitly asks Codex to modify files.

## Session Continuation

Sessions persist across Claude Code restarts. Detect continuation when user says "continue", "resume", "keep going", "add to that", or references previous Codex work.

**Resume**:
```bash
codex exec -c hide_agent_reasoning=true resume --last "prompt" 2>/tmp/codex_stderr.log
```

**Resume with multi-line**:
```bash
codex exec -c hide_agent_reasoning=true resume --last 2>/tmp/codex_stderr.log <<'EOF'
Multi-line prompt here
EOF
```

Key constraints:
- Resume inherits the original session's model and reasoning settings by default
- Add `-m` or `-c model_reasoning_effort=...` only when you intentionally want to override them
- `--last` resumes the globally most recent session (not per-instance)
- New/fresh requests → omit `resume --last`

## Common Errors

| Error | Fix |
|-------|-----|
| No prompt provided | Add prompt after `resume --last` |
| `--last` conflicts with `SESSION_ID` | Don't add `-` after `--last`; use heredoc for multi-line |
| stdout is not a terminal | Use `codex exec`, not `codex` |
| Not authenticated | Run `codex login` |

## Optional Local Verification

For version-sensitive CLI details, check your installed Codex directly:

```bash
codex --help
codex exec --help
codex exec resume --help
codex features list
```
