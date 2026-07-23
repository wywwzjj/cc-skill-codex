---
name: claude
description: Invoke Claude Code (`claude -p`) as a peer coding agent — flagship use is adversarial / steerable code review; also design analysis, debugging investigations, and delegated tasks. Use when the user mentions "Claude", wants a second opinion or a design challenged (even without saying "Claude"), or continues earlier Claude work. Sessions resume across restarts.
---

# Claude Code Integration

Claude is a peer coding agent invoked via `claude -p` — pick Claude vs. Codex by task fit, not role. Flagship use: **adversarial / steerable code review** — challenge the design, not just nitpick lines.

> Verified against Claude Code **v2.1.206**. Commands rarely change, but on older builds confirm with `claude --help`.

## Critical Rules

1. **Always invoke through `scripts/claude-ask.sh`** (next to this SKILL.md) — it wraps `claude -p --output-format json`, prints only the answer plus `SESSION_ID=` and `DETAILS=` trailer lines, fails loudly on `is_error`, and persists the full JSON envelope + stderr for on-demand inspection. Never plain `claude` (interactive TUI, hangs) and never hand-rolled `-p` pipelines (they silently swallow failures).
2. **Multi-line prompts go via stdin heredoc with the `CLAUDE_PROMPT_END` delimiter** — never `EOF`: reviewed code and diffs often contain a bare `EOF` line, which would terminate the heredoc and execute the rest as shell. If embedding external content, confirm it has no line equal to your delimiter.
3. **Resume by session ID** — the `SESSION_ID=` line from the prior call. `-c/--continue` resumes the most recent conversation in the cwd and races with any parallel `claude` run; fallback only. Bare `--resume` (no ID) opens an interactive picker and hangs under `-p`.
4. **Don't pin a model or restrict tools** — let Claude Code run with its configured defaults; pass `--model` only when the user asks for a specific one. The resumed session inherits the original session's model.

## Default Command

```bash
bash "<skill-dir>/scripts/claude-ask.sh" --effort high <<'CLAUDE_PROMPT_END'
Your prompt here. Multi-line is fine — that's why this uses a heredoc (Rule #2).
CLAUDE_PROMPT_END
```

`<skill-dir>` is the directory containing this SKILL.md. All flags pass through to `claude -p` verbatim.

Output is exactly three parts: the answer, `SESSION_ID=<id>` (only on success — a failed session is never offered for resume), and `DETAILS=<dir>`.

**Details on demand:** the `DETAILS` dir holds `envelope.json` (full result envelope: token usage, cost, `permission_denials`, model info) and `stderr.log`. Don't read them by default — pull them only when you need to debug or the user asks (e.g. `grep permission_denials <dir>/envelope.json`). On failure the script already shows the last 40 stderr lines; the full log stays in the dir.

Long high-effort runs can take several minutes — size the job first (`git diff --shortstat` for reviews) and run anything beyond a tiny 1–2 file change in the background if your foreground command timeout is short, reading the output when done.

## Use Cases

| User intent | Mode |
|---|---|
| "Challenge this design", "pressure-test", "is this the right approach?" | **adversarial review** |
| "Review this code", "check for bugs/security" | standard review |
| "Design X", "architect Y", "how should I structure..." | design analysis |
| "Why does X happen?", "investigate this deadlock" | debug investigation |
| "Have Claude fix...", "let Claude patch..." | delegated task |

## Adversarial Review (Flagship)

When the user wants Claude to question the design rather than nitpick lines:

```bash
bash "<skill-dir>/scripts/claude-ask.sh" --effort high <<'CLAUDE_PROMPT_END'
Adversarial review of <target>. Find the strongest reasons this change should not ship — your job is to break confidence in it, not validate it. Default to skepticism: happy-path-only behavior is a real weakness. Challenge the chosen approach and the assumptions it depends on — where would a different design have been safer or simpler?

Prioritize expensive, hard-to-detect failures: auth and trust boundaries, data loss or corruption, rollback/retry/idempotency gaps, race conditions and stale state, null/empty/timeout paths, migration and compatibility hazards.

Report only material findings, ordered by severity — no style nits. Each finding: file and line, what goes wrong, likely impact, concrete fix. Stay grounded: no invented code paths; mark inferences as inferences. One strong finding beats several weak ones; if the change looks safe, say so directly.

Report findings only — do not modify any files.

Focus: <user's specific concern, e.g., "the retry/caching strategy">
CLAUDE_PROMPT_END
```

Pays off most when **steered at a real risk area** — weave the user's specific focus into the prompt; generic review is much weaker.

**After presenting review findings, stop.** Don't auto-apply fixes — ask the user which findings, if any, they want fixed first, even when the fix is obvious.

For a diff-scoped review, just name the scope in the prompt (e.g. "review the uncommitted changes" or "review the diff against main") — Claude collects the diff itself. Embedding a diff you've already produced also works; if you do, check it has no line equal to your heredoc delimiter first.

## Session Continuation

Sessions persist across Codex restarts. Detect continuation when the user says "continue", "resume", "keep going", "add to that", or references previous Claude work.

**Resume by ID** (primary path — the `SESSION_ID=` line is in your context from the prior call):

```bash
bash "<skill-dir>/scripts/claude-ask.sh" --resume <SESSION_ID> <<'CLAUDE_PROMPT_END'
Multi-line follow-up here
CLAUDE_PROMPT_END
```

The session ID stays the same across resumes, and the resumed session inherits the original session's **model**; pass `--model`/`--effort` only to intentionally override.

**Fallback `--continue`** — only when the session ID is truly unrecoverable (check the prior call's `DETAILS` dir first: `envelope.json` contains `session_id`):

```bash
bash "<skill-dir>/scripts/claude-ask.sh" -c "prompt"
```

`-c` is scoped to the current directory but still races with any other `claude` run there. Prefer ID-based resume.

## Common Errors

| Symptom | Fix |
|-------|-----|
| Exit 3, error text on stderr | Claude ran but reported `is_error` (API error, budget, etc.) — the envelope in `DETAILS` has specifics; no session ID is emitted because the session failed |
| Exit 4, stderr tail shown | `claude` died before emitting usable JSON: bad flag, bad `--resume` ID (`No conversation found`), not authenticated, or an envelope missing `result`/`session_id`. Note: auth failures can also surface as exit 3 with valid JSON — both paths are handled |
| Hangs | Plain `claude` (interactive) or bare `--resume` without an ID (opens a picker); always go through the script and pass the ID |
| Wrong session resumed | Use `--resume <SESSION_ID>`, not `-c/--continue` — `-c` races with other `claude` runs in the same directory |
| Prompt truncated / shell errors after the call | Embedded content contained a line equal to your heredoc delimiter — pick another delimiter (Rule #2) |
| API connection errors when called from a sandboxed Codex session | `claude` needs network access and write access to `~/.claude`; if your own sandbox blocks these, the user must run Codex with network enabled or escalate this command |
| `python3: command not found` | The script needs python3 on PATH. Last-resort fallback: `claude -p --output-format text "prompt"` (no session ID capture, no is_error detection — one-shot only) |
| Not authenticated | Have the user run `claude` interactively once to log in, or see `claude auth --help` |

## Optional Local Verification

For version-sensitive details, check the installed Claude Code directly: `claude --help`, `claude -v`, `claude doctor`.
