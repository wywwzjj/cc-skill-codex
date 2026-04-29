# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is **cc-skill-codex**, a Claude Code plugin that integrates OpenAI's Codex CLI (v0.114.0+) as a peer coding agent. Both Codex and Claude can read and write code — they're picked by task fit, not by role. The skill's flagship use case is **adversarial / steerable code review**; it also covers standard review, deep design analysis, debugging investigations, and delegated tasks.

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
# Correct
codex exec resume --last <<'EOF'
Multi-line prompt
EOF

# Wrong - unescaped newlines break parsing
codex exec resume --last "Line 1
Line 2"

# Wrong - dash after --last parsed as SESSION_ID
codex exec resume --last -
```

### Session resume inherits prior settings by default
```bash
# Recommended - rely on the original session settings unless you intend to override them
codex exec resume --last "prompt"

# Override only when you explicitly want a different reasoning level or model
codex exec -c model_reasoning_effort=high resume --last "prompt"
```

### Default command structure
```bash
codex exec -s read-only \
  -c model_reasoning_effort=high \
  "prompt" 2>/tmp/codex_stderr.log
```

`stderr` redirection is required: it diverts session header / token stats / (when enabled) reasoning summaries to a log file so they don't pollute Claude's context.

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
