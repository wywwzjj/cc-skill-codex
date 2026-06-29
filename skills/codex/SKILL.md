---
name: codex
description: Invoke Codex CLI (`codex exec`) as a peer coding agent. Strongest fit is adversarial / steerable code review — pressure-test design tradeoffs, challenge chosen approaches, surface hidden assumptions, hunt risks in auth, data loss, race conditions, rollback. Also use for standard code review, deep design and architecture analysis, debugging investigations, algorithm design, and delegated tasks Claude shouldn't handle alone. Trigger this skill whenever the user mentions "Codex", asks for a thorough review or second opinion, wants to challenge a design decision, or has a hard problem worth handing off — even if they don't say "Codex" explicitly. Supports session continuation across Claude Code restarts for multi-day work.
---

# Codex CLI Integration

Codex is a peer coding agent invoked via `codex exec` — pick Codex vs. Claude by task fit, not role. Flagship use: **adversarial / steerable code review** — challenge the design, not just nitpick lines.

> Verified against Codex CLI **v0.142.2**. Commands rarely change, but on older builds confirm with `codex --help` / `codex exec --help`. The `codex exec review` subcommand in particular needs a recent build.

## Critical Rules

1. **Always use `codex exec`** — `codex` (interactive) fails in Claude Code
2. **Capture stderr to a per-call `LOG=$(mktemp)`, dump only on failure** (`2>"$LOG" … || cat "$LOG"`) — keeps session/token/reasoning noise out of context but still surfaces real errors. Not `2>/dev/null` (hides errors), not a fixed path like `/tmp/codex_stderr.log` (parallel calls clobber it). The Default Command section explains why each piece matters.
3. **Multi-line prompts must use heredoc** — literal newlines in a quoted arg are brittle once embedded in tool calls; also never add `-` after `--last`
4. **Resume by session ID, not `--last`** — `--last` resumes the globally most recent recorded session and races with any other Codex call (e.g., a parallel review in the same repo). Capture the session ID right after each new run and reuse it explicitly. `--last` is a fallback only when the ID was genuinely lost.
5. **Always pin `-s` explicitly, even on resume** — Codex applies your *configured* default sandbox (often `danger-full-access`) to any call without `-s`. Resume does **not** inherit the original session's sandbox (it inherits model + reasoning effort, but not this), so a read-only session silently escalates on resume unless you re-pin `-s read-only`.
6. **Don't pin a model** — let Codex CLI use its current default. Resumed sessions inherit the original session's model and reasoning effort.

## Default Command

```bash
LOG=$(mktemp) && codex exec -s read-only -c model_reasoning_effort=high 2>"$LOG" <<'EOF' && SESSION_ID=$(awk '/session id:/{id=$NF} END{if(id) print id; else exit 1}' "$LOG") && echo "SESSION_ID=$SESSION_ID" || cat "$LOG"
Your prompt here. Multi-line is fine — that's why this uses a heredoc (Rule #3).
EOF
```

The heredoc is the default form because Codex prompts (review/design/debug instructions) are almost always multi-line. For a genuinely one-line prompt you may swap the `<<'EOF' … EOF` for a quoted `"prompt"` argument before `2>"$LOG"` — everything else stays identical.

The `SESSION_ID=…` tail is **load-bearing** — it lifts the session ID into stdout (and thus context) so future turns resume by ID without re-grepping. **Don't simplify the chain**; each piece is deliberate: `LOG=$(mktemp)` keeps parallel calls from clobbering each other's id; `awk … else exit 1` fails the chain rather than echoing a blank `SESSION_ID=`; `|| cat "$LOG"` surfaces stderr on any failure (codex error *or* unparsed id) and never runs on success.

Long high-reasoning runs can exceed a 2-minute foreground timeout — run them in the background and read the log on completion.

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
LOG=$(mktemp) && codex exec -s read-only -c model_reasoning_effort=high 2>"$LOG" <<'EOF' && SESSION_ID=$(awk '/session id:/{id=$NF} END{if(id) print id; else exit 1}' "$LOG") && echo "SESSION_ID=$SESSION_ID" || cat "$LOG"
Adversarial review of <target>. Challenge the chosen approach. Surface hidden assumptions. Identify failure modes — race conditions, data loss, rollback gaps, auth weaknesses, reliability cliffs. Where would a different design have been safer or simpler?

Focus: <user's specific concern, e.g., "the retry/caching strategy">
EOF
```

Pays off most when **steered at a real risk area** — weave the user's specific focus into the prompt; generic review is much weaker.

### `codex exec review` — diff-scoped review

A purpose-built subcommand that auto-collects a diff so you don't hand-assemble one:

```bash
LOG=$(mktemp) && codex exec review -c sandbox_mode=read-only --uncommitted 2>"$LOG" || cat "$LOG"
# scope variants (swap the flag): --base main   |   --commit <SHA>
```

Two gotchas:
- **Scope flags can't combine with a custom `[PROMPT]`** — `--uncommitted`/`--base`/`--commit` plus a prompt fails with exit 2 (`cannot be used with '[PROMPT]'`). So `review` gives you *either* diff-scoping *or* steering, not both.
- **`review` rejects `-s` but does NOT default to read-only** — it takes no `-s/--sandbox`, yet applies your *configured* default sandbox, which may be `danger-full-access`. A review never needs to write, so pin it with `-c sandbox_mode=read-only` (shown above). `-c` and `-m` are accepted.

This is fire-and-forget — the session id is discarded on success; for follow-ups, add the Default Command's capture tail (`&& SESSION_ID=$(awk …) … || cat "$LOG"`) to retain it. Use `review` only for quick, **unsteered** diff-scoped passes; when you need to steer the review, use the free-form `codex exec` form above.

## Session Continuation

Sessions persist across Claude Code restarts. Detect continuation when the user says "continue", "resume", "keep going", "add to that", or references previous Codex work.

**Resume by ID** (primary path — the session ID is already in your context from the prior turn's `SESSION_ID=...` echo):

```bash
LOG=$(mktemp) && codex exec -s read-only resume <SESSION_ID> "prompt" 2>"$LOG" || cat "$LOG"
```

(Keep `-s read-only` even on resume — sandbox is **not** inherited; without it the call uses the configured default, often `danger-full-access`. Use `-s workspace-write` only for a delegated fix.)

**Resume with multi-line**:

```bash
LOG=$(mktemp) && codex exec -s read-only resume <SESSION_ID> 2>"$LOG" <<'EOF' || cat "$LOG"
Multi-line prompt here
EOF
```

No need to re-echo the ID on resume — it stays the same across the session.

**Fallback `--last`** — only when the session ID is truly unrecoverable (e.g., it scrolled out of context and you can't find it):

```bash
LOG=$(mktemp) && codex exec -s read-only resume --last "prompt" 2>"$LOG" || cat "$LOG"
```

`--last` is filtered by cwd by default but still races with any other Codex call in the same repo (parallel reviews, background tasks, the user invoking Codex directly). Prefer ID-based resume.

Other constraints:
- Resume inherits the original session's **model and reasoning effort** (but not sandbox — see Rule #5)
- Add `-m` or `-c model_reasoning_effort=...` only when you intentionally want to override the inherited values
- New/fresh requests → omit `resume <SESSION_ID>` entirely

**Flag ordering — `-s/--sandbox` is the trap.** `resume` accepts `-c` and `-m` (before *or* after the ID), but **not `-s/--sandbox`** — that's a `codex exec`-only flag, and placing it after `resume` fails with exit 2 (`unexpected argument`). Since you must re-pin `-s read-only` on every resume (Rule #5), the simplest rule is: **put every global flag before `resume`**.

```bash
codex exec -s read-only resume <SESSION_ID> "prompt"   # correct
codex exec resume <SESSION_ID> -s read-only "prompt"   # wrong: exit 2 (-c/-m here would be fine)
```

If Codex is run outside a trusted git directory, add `--skip-git-repo-check` (this one *is* a valid `resume` flag and may go after the ID).

## Common Errors

| Error | Fix |
|-------|-----|
| Wrong session resumed | Use `resume <SESSION_ID>`, not `--last` — `--last` races with parallel or recent Codex calls in the same repo |
| Session ID lost from context | Fall back to `resume --last` — the per-invocation `mktemp` log is ephemeral and its path isn't retained for re-grepping |
| No prompt provided | Add prompt after `resume <SESSION_ID>` (or `--last`) |
| `exit 2` / `unexpected argument '-s'` on resume | Move `-s` **before** the `resume` subcommand (`resume` rejects only `-s`; `-c`/`-m` are fine either side) |
| Resume/review ran with `danger-full-access` unexpectedly | Sandbox is **not** inherited and `review` rejects `-s`; pin it: `-s read-only` before `resume`, `-c sandbox_mode=read-only` for `review` |
| `Not inside a trusted directory` | Add `--skip-git-repo-check` (valid after the session ID), or run from inside the repo |
| `--last` conflicts with `SESSION_ID` | Don't add `-` after `--last`; use heredoc for multi-line |
| stdout is not a terminal | Use `codex exec`, not `codex` |
| Not authenticated | Run `codex login` |

## Optional Local Verification

For version-sensitive details, check your installed Codex directly: `codex --help`, `codex exec --help`, `codex exec resume --help`, `codex features list`.
