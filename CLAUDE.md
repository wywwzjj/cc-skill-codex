# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository is a **dual-direction peer-agent marketplace** holding two plugins:

- **cc-skill-codex** (for Claude Code users): Claude invokes OpenAI's Codex CLI (`codex exec`, verified against v0.142.2) as a peer coding agent
- **codex-skill-claude** (for Codex CLI users): Codex invokes Claude Code (`claude -p`, verified against v2.1.206) as a peer coding agent

Both directions share the same positioning: peer agents picked by task fit, not role; flagship use case is **adversarial / steerable code review**, plus standard review, deep design analysis, debugging investigations, and delegated tasks.

Neither skill pins a model — each relies on the callee CLI's configured default. This avoids per-release maintenance churn.

**One repo serves both ecosystems**: Codex CLI's plugin system (verified against codex-cli 0.145.0) reads Claude's `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` directly — no `.codex-plugin/` duplication needed. The two directions are separate plugins so each side installs only its own: a single plugin's skills would load into *both* agents, giving each a wrong-direction skill.

**Skill-path referencing is deliberately asymmetric** (both live-verified 2026-07-23): the Claude-side skill uses `${CLAUDE_SKILL_DIR}` — Claude Code (v2.1.129+, verified 2.1.206) substitutes the braced form in the SKILL.md body at load time (unbraced `$CLAUDE_SKILL_DIR` and `${CLAUDE_PLUGIN_ROOT}` are NOT substituted there). The Codex-side skill keeps the prose `<skill-dir>` placeholder — Codex performs no variable substitution; it hands the model each SKILL.md path via a "Skill roots" alias table. Don't "unify" these. Also: Codex snapshots installed plugin skills into a version-pinned cache (`~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/`), so SKILL.md edits reach Codex only after a version bump + plugin update (or remove/re-add) — even on the local machine.

## Architecture

```
cc-skill-codex-marketplace/           # Marketplace root (served to both Claude Code and Codex CLI)
├── .claude-plugin/
│   └── marketplace.json              # Marketplace config: lists both plugins
├── plugins/
│   ├── cc-skill-codex/               # Claude → Codex
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/codex/
│   │       ├── SKILL.md
│   │       └── scripts/codex-ask.sh
│   └── codex-skill-claude/           # Codex → Claude
│       ├── .claude-plugin/plugin.json
│       └── skills/claude/
│           ├── SKILL.md
│           └── scripts/claude-ask.sh
```

**Key distinction**: each `SKILL.md` is the authoritative workflow reference the host agent loads, while `README.md` remains the installation and usage guide for humans.

## Key Technical Constraints — cc-skill-codex (Claude → Codex)

### Invoke through the wrapper script
The skill's default path is `plugins/cc-skill-codex/skills/codex/scripts/codex-ask.sh`, which wraps `codex exec --json` (verified v0.145.0):

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" -c model_reasoning_effort=high <<'CODEX_PROMPT_END'
Multi-line prompt (heredoc is the default form; delimiter is CODEX_PROMPT_END, never EOF —
reviewed diffs often contain a bare EOF line, which would break out of the heredoc)
CODEX_PROMPT_END
```

Design rationale (the script encodes what the old inline chain did by prose):
- **Context economy**: stdout carries only the final agent message + `SESSION_ID=<id>` + `DETAILS=<dir>`. Reasoning summaries, command executions, and token stats never enter the caller's context.
- **Details on demand, never discarded**: the full `--json` event stream (`events.jsonl`) and stderr (`stderr.log`) are persisted in the per-call `DETAILS` dir (`mktemp -d`). Failure shows a 40-line stderr tail; everything else is pull-based.
- **Structured session ID**: taken from the `thread.started` event, not scraped from stderr prose (`session id:` wording misfired in practice — it once captured a literal `"$LOG"`). The ID is only emitted when a final answer arrived, so a failed call never leaves a resumable-looking ID; it's also recoverable later from `events.jsonl`.
- `codex exec` only — plain `codex` is interactive and fails with "stdout is not a terminal". Long high-reasoning runs can exceed a 2-minute foreground timeout — run in the background.

The pre-script inline chain (stderr + awk scraping) is kept as a documented fallback in the SKILL.md appendix for builds without `codex exec --json` or hosts without python3.

### Resume by session ID, not `--last`
`codex exec resume --last` resumes the most recent recorded session — cwd-filtered but still racing with any other Codex call in the same repo (parallel reviews, the user invoking Codex directly). Resume with the captured ID through the same script:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" resume <SESSION_ID> "prompt"
```

Resume inherits the original session's model and reasoning effort; override `-m`/`-c model_reasoning_effort` only to intentionally change the inherited values.

**`-s/--sandbox` must go before the `resume` subcommand.** `resume` accepts `-c`, `-m`, and `--json` (a genuine `resume` flag on v0.145.0) on either side, but `-s` placed after `resume` fails with exit 2 — which the wrapper surfaces as exit 3 with the usage error in the stderr tail. (`--skip-git-repo-check` is also a genuine `resume` flag and may follow the session ID.)

## Key Technical Constraints — codex-skill-claude (Codex → Claude)

All live-verified against claude 2.1.206; the traps mirror the Codex ones almost exactly. The skill's default path is `plugins/codex-skill-claude/skills/claude/scripts/claude-ask.sh` (wraps `claude -p --output-format json`; same output contract as codex-ask.sh: answer + `SESSION_ID=` + `DETAILS=` with the full envelope and stderr persisted for on-demand reads).

- **Always `claude -p`** — plain `claude` is interactive and hangs in non-interactive contexts
- **Maintainer decision (2026-07): the skills impose NO restriction flags** — no `--tools`, no `--safe-mode` on the Claude side, no `-s` pin on the Codex side. Both CLIs run with the user's configured defaults; restrictions had real side effects (read-only sandbox blocks network/temp writes; `--tools` removes Bash so Claude can't collect diffs; `--safe-mode` blocks the repo's CLAUDE.md/skills/MCP that help reviews). Keep it simple — don't re-add them when tracking CLI updates. For the record, the verified facts that motivated (and then un-motivated) them: `-p` auto-approves workspace writes; per-invocation flags don't survive `--resume`; model **is** inherited on resume
- **Failure is JSON too**: an unauthenticated/failed run can exit non-zero yet emit a valid envelope with `is_error:true` and a session ID — the script checks `is_error`, exits 3, and suppresses the ID so a failed session is never resumed by mistake (a naive pipe would report success)
- **`--resume` needs the ID in print mode** — bare `--resume` opens an interactive picker and hangs under `-p`; `-c/--continue` is cwd-scoped-most-recent and races like Codex's `--last`
- Multi-line prompts go via stdin heredoc with the `CLAUDE_PROMPT_END` delimiter (never `EOF` — same collision risk as the Codex side)

## Plugin Installation Flow

**Claude Code users** (install cc-skill-codex):
1. `/plugin marketplace add wywwzjj/cc-skill-codex`
2. `/plugin install cc-skill-codex@cc-skill-codex-marketplace`
3. Claude Code loads `plugins/cc-skill-codex/skills/codex/SKILL.md` when the skill is invoked
4. Skill triggers on: "Codex" keyword or session continuation phrases

**Codex CLI users** (install codex-skill-claude):
1. `codex plugin marketplace add wywwzjj/cc-skill-codex`
2. `codex plugin add codex-skill-claude@cc-skill-codex-marketplace`
3. Codex loads `plugins/codex-skill-claude/skills/claude/SKILL.md`
4. Skill triggers on: "Claude" keyword or session continuation phrases

Note: `codex plugin remove` requires the full `plugin@marketplace` form (a bare plugin name errors).

## Sandbox Modes (Codex)

The skill does not pass `-s` — Codex uses whatever sandbox is configured in the user's `config.toml`. The modes (`read-only` / `workspace-write` / `danger-full-access`) are the user's choice; pass `-s` only when the user explicitly asks for a specific one.

## Skill Maintenance Principles

When updating either skill to track its callee CLI's updates:

### Focus on the calling scenario
Each skill enables **one agent to call the other's CLI** for high-reasoning tasks (`codex exec` for cc-skill-codex, `claude -p` for codex-skill-claude). Neither is a comprehensive manual for the callee.

### What to include
- Stable commands the calling agent actually uses
- Resume rules and heredoc examples
- A few common failures users hit in practice
- Pointers to local CLI help for anything version-sensitive

### What to exclude
- Mirrored `--help` output or full feature inventories
- Large configuration references that duplicate upstream docs
- Callee features the calling agent will not invoke in this skill
- Anything likely to churn every CLI release unless it is critical to the skill

### Guiding question
> "Will the calling agent use this when invoking the callee for design/review/debug tasks?"

If no, don't add it to the skill documentation.

### Design reference
OpenAI's official Claude→Codex plugin is [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) — a heavyweight design (persistent `codex app-server` JSON-RPC broker, Node 18+ runtime, slash commands, background job tracking, Stop-hook review gate). This repo deliberately stays lightweight (one-shot `codex exec --json` + bash/python3, dual-direction). Its adversarial-review prompt structure and review-result discipline (present findings, never auto-fix) are adopted in both SKILL.md files; consult it for prompt-quality ideas, not architecture.

### Preferred documentation shape
- Keep each `SKILL.md` authoritative for its workflow
- For volatile CLI details, tell users to run the callee's own help (`codex --help`, `codex exec --help`, `claude --help`)
- **Verify every behavioral claim against the live binary before documenting it** — both CLIs have unsafe defaults and non-obvious inheritance rules that changed across releases
