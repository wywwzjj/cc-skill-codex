# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is **cc-skill-codex**, a Claude Code plugin that integrates OpenAI's Codex CLI (v0.101.0+) with GPT-5.3 capabilities. The core philosophy is **Codex = Brain (thinking), Claude = Hands (implementation)**.

## Architecture

```
cc-skill-codex-marketplace/           # Marketplace root
├── .claude-plugin/
│   ├── plugin.json                   # Plugin metadata (name, version, author)
│   └── marketplace.json              # Marketplace config (plugin listings)
├── skills/codex/
│   ├── SKILL.md                      # Main skill definition - loaded by Claude Code
│   └── references/                   # User documentation (not loaded by Claude Code)
│       ├── command-patterns.md       # Design → Implementation workflows
│       ├── session-workflows.md      # Session continuation patterns
│       ├── troubleshooting.md        # Error solutions
│       ├── codex-config.md           # Configuration reference
│       ├── codex-help.md             # CLI flags and commands
│       └── advanced-patterns.md      # Advanced options
```

**Key distinction**: `SKILL.md` is the skill definition that Claude Code loads when the skill is invoked. Files in `references/` are documentation for end users.

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

### Session resume requires model flag before `resume`
```bash
# Correct - model before resume
codex exec -m gpt-5.3-codex -c hide_agent_reasoning=true resume --last "prompt"

# Incorrect - model mismatch warning
codex exec resume --last "prompt"  # Uses default model, not original session's model
```

### Default command structure
```bash
codex exec -m gpt-5.3-codex -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "prompt"
```

## Plugin Installation Flow

1. User adds marketplace: `/plugin marketplace add wywwzjj/cc-skill-codex`
2. User installs plugin: `/plugin install cc-skill-codex@cc-skill-codex-marketplace`
3. Claude Code loads `skills/codex/SKILL.md` when skill is invoked
4. Skill triggers on: "Codex" keyword, "GPT-5.3" mention, or session continuation phrases

## Available Models

| Model | Use Case |
|-------|----------|
| `gpt-5.3` | General reasoning, architecture |
| `gpt-5.3-codex` | Code editing (recommended default) |

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
- Version number updates
- Changes to `codex exec` command (new flags, parameters)
- `codex review` command (useful for code review scenarios)
- Feature flags table updates (affects `--enable`/`--disable` usage)
- Troubleshooting for errors Claude might encounter

### What to exclude
- Codex's own features that Claude won't invoke:
  - `codex app` (macOS app launcher)
  - `codex fork` (session forking)
  - `codex cloud` (cloud task management)
  - Codex's internal skills system (`~/.agents/skills`)
  - Codex's plan mode (`/plan` command)
  - Personality configuration
- Detailed configuration for features Claude doesn't use
- User-facing Codex features unrelated to `codex exec`

### Guiding question
> "Will Claude use this when calling `codex exec` for design/review/debug tasks?"

If no, don't add it to the skill documentation.
