# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is **cc-skill-codex**, a Claude Code plugin that integrates OpenAI's Codex CLI (v0.114.0+) with `gpt-5.4` as the default model. The core philosophy is **Codex = Brain (thinking), Claude = Hands (implementation)**.

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
codex exec -c hide_agent_reasoning=true resume --last <<'EOF'
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
codex exec -c hide_agent_reasoning=true resume --last "prompt"

# Override only when you explicitly want a different model or reasoning level
codex exec -m gpt-5.4 -c model_reasoning_effort=high -c hide_agent_reasoning=true resume --last "prompt"
```

### Default command structure
```bash
codex exec -m gpt-5.4 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "prompt"
```

## Plugin Installation Flow

1. User adds marketplace: `/plugin marketplace add wywwzjj/cc-skill-codex`
2. User installs plugin: `/plugin install cc-skill-codex@cc-skill-codex-marketplace`
3. Claude Code loads `skills/codex/SKILL.md` when skill is invoked
4. Skill triggers on: "Codex" keyword, "`gpt-5.4`" mention, or session continuation phrases

## Default Model

| Model | Use Case |
|-------|----------|
| `gpt-5.4` | Default model for design, architecture, review, and debug analysis |

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
