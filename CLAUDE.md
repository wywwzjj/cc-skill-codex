# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is **cc-skill-codex**, a Claude Code plugin that integrates OpenAI's Codex CLI (verified against v0.142.2) as a peer coding agent. Both Codex and Claude can read and write code — they're picked by task fit, not by role. The skill's flagship use case is **adversarial / steerable code review**; it also covers standard review, deep design analysis, debugging investigations, and delegated tasks.

The skill does **not** pin a specific Codex model — it relies on whatever Codex CLI's current default is. This avoids per-release maintenance churn.

## Architecture

```
cc-skill-codex-marketplace/           # Marketplace root
├── .claude-plugin/
│   ├── plugin.json                   # Plugin metadata (name, version, author)
│   └── marketplace.json              # Marketplace config (plugin listings)
├── skills/codex/
│   └── SKILL.md                      # Main skill definition and maintained docs
```

**Key distinction**: `SKILL.md` is the authoritative workflow reference Claude Code loads, while `README.md` remains the installation and usage guide for humans.

## Key Technical Constraints

### Always use `codex exec`
- `codex exec` = non-interactive mode (works in Claude Code)
- `codex` = interactive mode (fails in Claude Code with "stdout is not a terminal")

### Multi-line prompts require heredoc
```bash
# Correct (note -s read-only re-pinned before the subcommand)
codex exec -s read-only resume <SESSION_ID> <<'EOF'
Multi-line prompt
EOF

# Fragile - literal newlines in a quoted arg work in bash/zsh but are brittle
# when embedded in tool calls; prefer heredoc for multi-line prompts
codex exec resume <SESSION_ID> "Line 1
Line 2"

# Wrong - dash after --last parsed as SESSION_ID
codex exec resume --last -
```

### Resume by session ID, not `--last`
`codex exec resume --last` resumes the globally most recent recorded session — it's filtered by cwd but still races with any other Codex call in the same repo (parallel reviews, the user invoking Codex directly, etc.). Capture the session ID at the end of each new run and reuse it:

```bash
# First call — capture session id into stdout (and therefore Claude's context)
LOG=$(mktemp) && codex exec -s read-only -c model_reasoning_effort=high "prompt" 2>"$LOG" \
  && SESSION_ID=$(awk '/session id:/{id=$NF} END{if(id) print id; else exit 1}' "$LOG") \
  && echo "SESSION_ID=$SESSION_ID" \
  || cat "$LOG"

# Resume with the captured id (id is in Claude's context from the prior turn).
# Re-pin -s read-only: sandbox is NOT inherited on resume.
LOG=$(mktemp) && codex exec -s read-only resume <SESSION_ID> "prompt" 2>"$LOG" || cat "$LOG"
```

The `SESSION_ID=…` tail is load-bearing: it lifts the session id from the per-call log into stdout. Four deliberate choices: (1) the `&&` chain emits the id only when codex *succeeded*, never a stale value; (2) the `awk … else exit 1` fails the chain if no session id was parsed, so a blank `SESSION_ID=` is never recorded; (3) `LOG=$(mktemp)` gives each call its own log file — a fixed shared path (`/tmp/codex_stderr.log`) would let parallel Codex calls clobber each other's session id; (4) the trailing `|| cat "$LOG"` fires on any failure and surfaces the captured stderr, so errors stay debuggable instead of being swallowed by `2>/dev/null`. Use `--last` only as a fallback when the id is unrecoverable.

Resume inherits the original session's model and reasoning effort — but **not** its sandbox, which resets to the configured default (often `danger-full-access`). So pass `-s read-only` on every resume, and override `-m`/`-c model_reasoning_effort` only when you want to change the inherited values:

```bash
codex exec -s read-only resume <SESSION_ID> "prompt"
```

**`-s/--sandbox` must go before the `resume` subcommand.** `resume` accepts `-c` and `-m` on either side, but **not `-s/--sandbox`** — that's a `codex exec`-only flag, so placing it after `resume` fails with exit 2 (`unexpected argument`). Combined with the no-inheritance fact above, this means: always put `-s read-only` (and any global flag) before `resume`. (`--skip-git-repo-check` is a genuine `resume` flag and may follow the session ID when running outside a trusted git directory.)

### Default command structure
```bash
LOG=$(mktemp) && codex exec -s read-only \
  -c model_reasoning_effort=high \
  "prompt" 2>"$LOG" \
  && SESSION_ID=$(awk '/session id:/{id=$NF} END{if(id) print id; else exit 1}' "$LOG") \
  && echo "SESSION_ID=$SESSION_ID" \
  || cat "$LOG"
```

`stderr` redirection diverts session header / token stats / reasoning summaries to a per-call log file (via `mktemp`) so they don't pollute Claude's context and parallel calls can't clobber each other. The trailing `awk`+`echo` puts the session id where future turns can find it (Claude's conversation context), and fails the chain rather than recording a blank id if none was parsed. `|| cat "$LOG"` then surfaces the captured stderr on failure — keep it instead of `2>/dev/null`, which would hide the error. Long high-reasoning runs can exceed a 2-minute foreground timeout — run them in the background and read the log when notified.

## Plugin Installation Flow

1. User adds marketplace: `/plugin marketplace add wywwzjj/cc-skill-codex`
2. User installs plugin: `/plugin install cc-skill-codex@cc-skill-codex-marketplace`
3. Claude Code loads `skills/codex/SKILL.md` when skill is invoked
4. Skill triggers on: "Codex" keyword or session continuation phrases

## Sandbox Modes

| Mode | Description |
|------|-------------|
| `read-only` | Default for design/review tasks |
| `workspace-write` | Only when Codex must modify files |
| `danger-full-access` | Full system access (rarely needed) |

## Skill Maintenance Principles

When updating this skill to track Codex CLI updates:

### Focus on Claude's calling scenario
This skill enables **Claude to call `codex exec`** for high-reasoning tasks. It is NOT a comprehensive Codex manual.

### What to include
- Stable commands Claude actually uses
- Resume rules and heredoc examples
- A few common failures Claude users hit in practice
- Pointers to local CLI help for anything version-sensitive

### What to exclude
- Mirrored `--help` output or full feature inventories
- Large configuration references that duplicate upstream docs
- Codex features Claude will not invoke in this skill
- Anything likely to churn every CLI release unless it is critical to the skill

### Guiding question
> "Will Claude use this when calling `codex exec` for design/review/debug tasks?"

If no, don't add it to the skill documentation.

### Preferred documentation shape
- Keep `SKILL.md` authoritative for the workflow
- For volatile CLI details, tell users to run `codex --help`, `codex exec --help`, or `codex exec resume --help`
