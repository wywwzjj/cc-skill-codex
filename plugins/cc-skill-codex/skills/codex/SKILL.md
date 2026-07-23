---
name: codex
description: Invoke Codex CLI (`codex exec`) as a peer coding agent — flagship use is adversarial / steerable code review; also design analysis, debugging investigations, and delegated tasks. Use when the user mentions "Codex", wants a second opinion or a design challenged (even without saying "Codex"), or continues earlier Codex work. Sessions resume across restarts.
---

# Codex CLI Integration

Codex is a peer coding agent invoked via `codex exec` — pick Codex vs. Claude by task fit, not role. Flagship use: **adversarial / steerable code review** — challenge the design, not just nitpick lines.

> Base commands verified against Codex CLI **v0.142.2**; the wrapper script's `--json` event stream verified against **v0.145.0**. On older builds confirm with `codex --help` / `codex exec --help`; if `codex exec --json` is unsupported, use the inline fallback in the appendix.

## Critical Rules

1. **Always invoke through `scripts/codex-ask.sh`** (next to this SKILL.md) — it wraps `codex exec --json`, prints only the final answer plus `SESSION_ID=` and `DETAILS=` trailer lines, and persists the full event stream + stderr for on-demand inspection. The only two exceptions: `codex exec review` (own output shape, called directly — see below) and the appendix inline fallback for hosts where the wrapper can't run. Never plain `codex` (interactive, fails with "stdout is not a terminal") and never hand-rolled stderr-scraping pipelines — stderr's `session id:` wording is not a stable interface; `thread.started` in the JSON stream is.
2. **Multi-line prompts go via stdin heredoc with the `CODEX_PROMPT_END` delimiter** — never `EOF`: reviewed code and diffs often contain a bare `EOF` line, which would terminate the heredoc and execute the rest as shell. If embedding external content, confirm it has no line equal to your delimiter.
3. **Resume by session ID, not `--last`** — `--last` resumes the most recent recorded session and races with any other Codex call in the same repo (parallel reviews, the user invoking Codex directly). The `SESSION_ID=` line from the prior call is the resume handle; `--last` is a fallback only when the ID is genuinely unrecoverable (check the prior call's `DETAILS` dir first — `events.jsonl` contains `thread.started` with the ID).
4. **Don't pin a model or a sandbox** — let Codex run with its configured defaults; pass `-m`/`-s` only when the user explicitly asks. Resumed sessions inherit the original session's model and reasoning effort. If you do pass `-s`, it must go **before** the `resume` subcommand (after it the call fails — `unexpected argument` in the stderr tail).

## Default Command

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" -c model_reasoning_effort=high <<'CODEX_PROMPT_END'
Your prompt here. Multi-line is fine — that's why this uses a heredoc (Rule #2).
CODEX_PROMPT_END
```

`${CLAUDE_SKILL_DIR}` is substituted by Claude Code with this skill's directory at load time (v2.1.129+; on older builds replace it with the skill's base directory shown above). All flags pass through to `codex exec` verbatim.

Output is exactly three parts: the final answer, `SESSION_ID=<id>` (from the `thread.started` event — only emitted when a final answer arrived), and `DETAILS=<dir>`.

**Details on demand:** the `DETAILS` dir holds `events.jsonl` (the full event stream — reasoning summaries, command executions, token usage, and the session ID) and `stderr.log`. Don't read them by default — pull them only when you need to debug, reconstruct what Codex actually executed, or recover a lost session ID. On failure the script already shows the last 40 stderr lines; the full log stays in the dir.

Long high-reasoning runs can exceed a 2-minute foreground timeout — size the job first (`git diff --shortstat` for reviews) and run anything beyond a tiny 1–2 file change in the background, reading the output on completion.

## Use Cases

| User intent | Mode |
|---|---|
| "Challenge this design", "pressure-test", "is this the right approach?" | **adversarial review** |
| "Review this code", "check for bugs/security" | standard review |
| "Design X", "architect Y", "how should I structure..." | design analysis |
| "Why does X happen?", "investigate this deadlock" | debug investigation |
| "Have Codex fix...", "let Codex patch..." | delegated task |

## Adversarial Review (Flagship)

When the user wants Codex to question the design rather than nitpick lines:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" -c model_reasoning_effort=high <<'CODEX_PROMPT_END'
Adversarial review of <target>. Find the strongest reasons this change should not ship — your job is to break confidence in it, not validate it. Default to skepticism: happy-path-only behavior is a real weakness. Challenge the chosen approach and the assumptions it depends on — where would a different design have been safer or simpler?

Prioritize expensive, hard-to-detect failures: auth and trust boundaries, data loss or corruption, rollback/retry/idempotency gaps, race conditions and stale state, null/empty/timeout paths, migration and compatibility hazards.

Report only material findings, ordered by severity — no style nits. Each finding: file and line, what goes wrong, likely impact, concrete fix. Stay grounded: no invented code paths; mark inferences as inferences. One strong finding beats several weak ones; if the change looks safe, say so directly.

Report findings only — do not modify any files.

Focus: <user's specific concern, e.g., "the retry/caching strategy">
CODEX_PROMPT_END
```

Pays off most when **steered at a real risk area** — weave the user's specific focus into the prompt; generic review is much weaker.

**After presenting review findings, stop.** Don't auto-apply fixes — ask the user which findings, if any, they want fixed first, even when the fix is obvious.

### `codex exec review` — diff-scoped review

A purpose-built subcommand that auto-collects a diff so you don't hand-assemble one. It has its own output shape — call it directly, not through the wrapper:

```bash
LOG=$(mktemp) && codex exec review --uncommitted 2>"$LOG" || cat "$LOG"
# scope variants (swap the flag): --base main   |   --commit <SHA>
```

One gotcha: **scope flags can't combine with a custom `[PROMPT]`** — `--uncommitted`/`--base`/`--commit` plus a prompt fails with exit 2 (`cannot be used with '[PROMPT]'`). So `review` gives you *either* diff-scoping *or* steering, not both.

This is fire-and-forget — the session id is discarded on success. Use `review` only for quick, **unsteered** diff-scoped passes; when you need to steer the review or continue the session afterwards, use the wrapper-script form above.

## Session Continuation

Sessions persist across Claude Code restarts. Detect continuation when the user says "continue", "resume", "keep going", "add to that", or references previous Codex work.

**Resume by ID** (primary path — the `SESSION_ID=` line is in your context from the prior call):

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" resume <SESSION_ID> <<'CODEX_PROMPT_END'
Multi-line follow-up here
CODEX_PROMPT_END
```

The session ID stays the same across resumes.

**Fallback `--last`** — only when the session ID is truly unrecoverable (check the prior call's `DETAILS` dir first: `grep thread.started <dir>/events.jsonl`):

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" resume --last "prompt"
```

Other constraints:
- Resume inherits the original session's **model and reasoning effort**; add `-m` or `-c model_reasoning_effort=...` only to intentionally override
- New/fresh requests → omit `resume <SESSION_ID>` entirely
- **Flag ordering:** `resume` accepts `-c`, `-m`, and `--json` on either side of the ID, but `-s` must go **before** `resume` — after it, codex rejects it as an unexpected argument
- If Codex runs outside a trusted git directory, add `--skip-git-repo-check` (a genuine `resume` flag; may go after the session ID)

## Common Errors

| Symptom | Fix |
|-------|-----|
| Exit 3, `DETAILS=` but no answer | The event stream ended without a final agent message — codex errored (bad flag, auth) or was interrupted; the stderr tail shown has the cause, full log in `DETAILS` |
| Wrong session resumed | Use `resume <SESSION_ID>`, not `--last` — `--last` races with parallel or recent Codex calls in the same repo |
| Session ID lost from context | Recover it from the prior call's `DETAILS` dir (`grep thread.started <dir>/events.jsonl`); only then fall back to `resume --last` |
| Exit 3 with `unexpected argument '-s'` in the stderr tail | You placed `-s` after the `resume` subcommand — move it before (`-c`/`-m`/`--json` are fine either side). Codex's own exit 2 always surfaces as wrapper exit 3; the stderr tail has the real cause |
| `Not inside a trusted directory` | Add `--skip-git-repo-check` (valid after the session ID), or run from inside the repo |
| Prompt truncated / shell errors after the call | Embedded content contained a line equal to your heredoc delimiter — pick another delimiter (Rule #2) |
| `unexpected argument '--json'` in the stderr tail | Codex build too old for the wrapper (needs `codex exec --json`; verified v0.145.0) — use the inline fallback below |
| `python3: command not found` | The script needs python3 on PATH — use the inline fallback below |
| stdout is not a terminal | You ran plain `codex` — always go through the script (or `codex exec` in the fallback) |
| Not authenticated | Run `codex login` |

## Appendix: Inline Fallback (no script / no `--json` / no python3)

The pre-script form — scrapes the session ID from stderr instead of the event stream. Less robust (the `session id:` stderr wording is not a stable interface); use only when the wrapper can't run:

```bash
LOG=$(mktemp) && codex exec -c model_reasoning_effort=high 2>"$LOG" <<'CODEX_PROMPT_END' && SESSION_ID=$(awk '/session id:/{id=$NF} END{if(id) print id; else exit 1}' "$LOG") && echo "SESSION_ID=$SESSION_ID" || cat "$LOG"
Your prompt here.
CODEX_PROMPT_END
```

Each piece is deliberate — don't simplify: `LOG=$(mktemp)` keeps parallel calls from clobbering each other; `awk … else exit 1` fails the chain rather than echoing a blank `SESSION_ID=`; `|| cat "$LOG"` surfaces stderr on any failure. Resume form: `LOG=$(mktemp) && codex exec resume <SESSION_ID> "prompt" 2>"$LOG" || cat "$LOG"`.

## Optional Local Verification

For version-sensitive details, check your installed Codex directly: `codex --help`, `codex exec --help`, `codex exec resume --help`, `codex features list`.
