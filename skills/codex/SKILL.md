---
name: codex
description: Invoke Codex CLI (`codex exec`) as a peer coding agent. Strongest fit is adversarial / steerable code review — pressure-test design tradeoffs, challenge chosen approaches, surface hidden assumptions, hunt risks in auth, data loss, race conditions, rollback. Also use for standard code review, deep design and architecture analysis, debugging investigations, algorithm design, and delegated tasks Claude shouldn't handle alone. Trigger this skill whenever the user mentions "Codex", asks for a thorough review or second opinion, wants to challenge a design decision, or has a hard problem worth handing off — even if they don't say "Codex" explicitly. Supports session continuation across Claude Code restarts for multi-day work.
---

# Codex CLI Integration (v0.114.0+)

Codex is a peer coding agent invoked via `codex exec`. Both Codex and Claude can read and write code — pick by task fit, not by role. The flagship use case is **adversarial / steerable code review**: not line-level nitpicks, but challenging the design itself.

## Critical Rules

1. **Always use `codex exec`** — `codex` (interactive) fails in Claude Code
2. **Always redirect stderr to `/tmp/codex_stderr.log`** — intermediate process output (session info, tool calls, token stats, reasoning summaries) goes to stderr; redirect to a fixed temp file to avoid filling context while keeping it accessible for debugging
3. **Multi-line prompts must use heredoc** — never use unescaped newlines in quotes, never add `-` after `--last`
4. **Resume by session ID, not `--last`** — `--last` resumes the globally most recent recorded session and races with any other Codex call (e.g., a parallel review in the same repo). Capture the session ID right after each new run and reuse it explicitly. `--last` is a fallback only when the ID was genuinely lost.
5. **Don't pin a model** — let Codex CLI use its current default. Resumed sessions inherit the original session's settings (model + reasoning effort).

## Default Command

```bash
codex exec -s read-only \
  -c model_reasoning_effort=high \
  "prompt" 2>/tmp/codex_stderr.log \
  && echo "SESSION_ID=$(grep 'session id:' /tmp/codex_stderr.log | tail -1 | awk '{print $NF}')"
```

The `&& echo "SESSION_ID=..."` tail is **load-bearing**: it lifts the session ID from `/tmp/codex_stderr.log` (which is overwritten by the next call) into stdout, where it becomes part of the conversation context. Future turns can then resume by ID without re-grepping.

Default to **read-only** — most Codex invocations are analysis or review. Use `-s workspace-write` only when the user explicitly delegates a fix/refactor to Codex.

## Use Cases

| User intent | Mode | Sandbox |
|---|---|---|
| "Challenge this design", "pressure-test", "is this the right approach?" | **adversarial review** | `read-only` |
| "Review this code", "check for bugs/security" | standard review | `read-only` |
| "Design X", "architect Y", "how should I structure..." | design analysis | `read-only` |
| "Why does X happen?", "investigate this deadlock" | debug investigation | `read-only` |
| "Have Codex fix...", "let Codex patch..." | delegated task | `workspace-write` |

## Adversarial Review (Flagship)

When the user wants Codex to question the design rather than nitpick lines:

```bash
codex exec -s read-only -c model_reasoning_effort=high 2>/tmp/codex_stderr.log <<'EOF'
Adversarial review of <target>. Challenge the chosen approach. Surface hidden assumptions. Identify failure modes — race conditions, data loss, rollback gaps, auth weaknesses, reliability cliffs. Where would a different design have been safer or simpler?

Focus: <user's specific concern, e.g., "the retry/caching strategy">
EOF
echo "SESSION_ID=$(grep 'session id:' /tmp/codex_stderr.log | tail -1 | awk '{print $NF}')"
```

This pays off most when **steered at a real risk area**. Always weave the user's specific focus into the prompt — generic adversarial review is much weaker than focused.

## Session Continuation

Sessions persist across Claude Code restarts. Detect continuation when the user says "continue", "resume", "keep going", "add to that", or references previous Codex work.

**Resume by ID** (primary path — the session ID is already in your context from the prior turn's `SESSION_ID=...` echo):

```bash
codex exec resume <SESSION_ID> "prompt" 2>/tmp/codex_stderr.log
```

**Resume with multi-line**:

```bash
codex exec resume <SESSION_ID> 2>/tmp/codex_stderr.log <<'EOF'
Multi-line prompt here
EOF
```

No need to re-echo the ID on resume — it stays the same across the session.

**Fallback `--last`** — only when the session ID is truly unrecoverable (e.g., it scrolled out of context and you can't find it):

```bash
codex exec resume --last "prompt" 2>/tmp/codex_stderr.log
```

`--last` is filtered by cwd by default but still races with any other Codex call in the same repo (parallel reviews, background `--rescue`-style tasks, the user invoking Codex directly). Prefer ID-based resume.

Other constraints:
- Resume inherits the original session's model and reasoning settings by default
- Add `-m` or `-c model_reasoning_effort=...` only when you intentionally want to override them
- New/fresh requests → omit `resume <SESSION_ID>` entirely

## Common Errors

| Error | Fix |
|-------|-----|
| Wrong session resumed | Use `resume <SESSION_ID>`, not `--last` — `--last` races with parallel or recent Codex calls in the same repo |
| Session ID lost from context | Grep `/tmp/codex_stderr.log` immediately if it hasn't been overwritten yet; otherwise fall back to `--last` |
| No prompt provided | Add prompt after `resume <SESSION_ID>` (or `--last`) |
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
