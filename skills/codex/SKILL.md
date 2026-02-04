---
name: codex
description: Invoke Codex CLI for high-reasoning tasks requiring GPT-5.2 capabilities. Use when user mentions "Codex", requests design/architecture, code review, debug analysis, or algorithm design. Codex = Brain (thinking), Claude = Hands (implementation). Supports session continuation for long-term projects.
---

# cc-skill-codex: Codex CLI Integration for Claude Code

**Codex CLI Version**: v0.95.0+

---

## ⚠️ CRITICAL Requirements

### Always Use `codex exec`
- ✅ `codex exec` (non-interactive mode)
- ❌ `codex` (interactive mode fails in Claude Code)

### Multi-line Prompts: Use Heredoc
```bash
# ✅ CORRECT - heredoc (auto-reads from stdin)
codex exec resume --last <<'EOF'
Multi-line prompt
EOF

# ❌ WRONG - unescaped newlines
codex exec resume --last "Line 1
Line 2"

# ❌ WRONG - don't add `-` (parsed as SESSION_ID)
codex exec resume --last -
```

**Key**: When PROMPT omitted, `codex exec` auto-reads stdin. Never add `-` after `--last`.

---

## When to Use This Skill

**Recommended Pattern: Codex = Brain, Claude = Hands**

Invoke Codex for:
- **Design & Architecture**: "Use Codex to design a REST API"
- **Planning & Strategy**: "Use Codex to plan a caching layer"
- **Code Review**: "Use Codex to review this for security issues"
- **Debug Analysis**: "Use Codex to analyze why this deadlocks"
- **Algorithm Design**: "Use Codex to design a consensus algorithm"

Then use Claude to implement what Codex designed.

This skill triggers when:
- User explicitly mentions "Codex" or "Use Codex"
- User requests "GPT-5.2" capabilities
- User wants to continue a previous Codex session

## How It Works

### Recommended Approach

**Primary use case: High-level reasoning (read-only)**
```bash
codex exec -m gpt-5.2-codex -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "<design/review/debug prompt>"
```

**Default to read-only** - let Claude handle actual implementation.

Use workspace-write only when user explicitly requests Codex to modify files (rare).

### Default Configuration

All Codex invocations use these defaults unless user specifies otherwise:

| Parameter | Default Value | CLI Flag | Notes |
|-----------|---------------|----------|-------|
| Model | `gpt-5.2-codex` | `-m gpt-5.2-codex` | Latest agentic coding model (recommended) |
| Model (general) | `gpt-5.2` | `-m gpt-5.2` | For non-code tasks requiring broad knowledge |
| Sandbox | `read-only` | `-s read-only` | Safe default (general tasks) |
| Sandbox (code editing) | `workspace-write` | `-s workspace-write` | Allows file modifications |
| Reasoning Effort | `high` | `-c model_reasoning_effort=high` | Maximum reasoning capability |
| Hide Reasoning | `true` | `-c hide_agent_reasoning=true` | **IMPORTANT**: Hide thinking output to reduce context |

**Note on defaults**: `web_search_request`, `view_image_tool`, `parallel_shell` are enabled by default - no CLI flag needed. Use `--disable <feature>` only if you need to turn them off.

### Available Models

| Model | Description |
|-------|-------------|
| `gpt-5.2-codex` | Latest frontier agentic coding model (recommended) |
| `gpt-5.2` | Latest frontier model with improvements across knowledge, reasoning and coding |

### Common Flags

- `-m`: Model (`gpt-5.2-codex`, `gpt-5.2`)
- `-s`: Sandbox (`read-only`, `workspace-write`, `danger-full-access`)
- `-c`: Config (e.g., `model_reasoning_effort=high`)
- `-i`: Attach images
- `-p`: Profile (load config profile from `~/.codex/config.toml`)
- `--full-auto`: workspace-write + on-request approval
- `--skip-git-repo-check`: Allow running outside Git repository
- `--output-schema`: Specify JSON Schema for structured output

See `references/codex-help.md` for complete flag list.

### Code Review Command

For code review tasks, use the dedicated `codex review` command (non-interactive):

```bash
codex review --uncommitted              # Review staged, unstaged, and untracked changes
codex review --base main                # Review changes against main branch
codex review --commit HEAD~3            # Review changes introduced by a specific commit
codex review "Check for security issues"  # Custom review instructions
```

**When to use**: User asks to review code changes, PR review, or security audit of recent commits.

## Session Continuation

**Key Advantage**: Codex sessions persist across Claude Code restarts - unlike Claude's context, Codex maintains full conversation history days or weeks later.

### When to Resume

Detect continuation when user says:
- "continue", "resume", "keep going", "add to that"
- References previous Codex work
- Iterative development on same task

### How to Resume

**⚠️ Important Limitations**:
- **Concurrent sessions**: `--last` points to globally most recent session. Multiple Claude Code instances may conflict.
- **Model matching**: Must specify same model used in original session (e.g., `-m gpt-5.2-codex`), otherwise you'll get a warning and degraded performance.

**Basic usage** (single Claude Code instance):

```bash
# ✅ Match original model (-m before resume)
codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true resume --last "Add error handling"

# ✅ Multi-line with model
codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true resume --last <<'EOF'
Multi-line prompt here
EOF
```

**Advanced usage** (multiple instances - track session ID):

```bash
# 1. Capture session ID from first invocation
SESSION_ID=$(codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true "initial prompt" 2>&1 | grep -o 'session id: [a-f0-9-]*' | cut -d' ' -f3)

# 2. Resume with explicit session ID and model
codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true resume "$SESSION_ID" <<'EOF'
Continue prompt
EOF
```

### New Session vs. Resume

| Scenario | Command |
|----------|---------|
| New independent request | `codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true "prompt"` |
| User says "fresh start" | `codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true "prompt"` |
| User says "continue" | `codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true resume --last "prompt"` |
| Building on previous work | `codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true resume --last "prompt"` |

**Sessions auto-save** - no manual tracking needed. See `references/session-workflows.md` for detailed examples and workflows.

## Common Errors

| Error | Fix |
|-------|-----|
| No prompt provided | Add prompt: `codex exec -c hide_agent_reasoning=true resume --last "prompt"` |
| Multi-line parsing error | Use heredoc (see CRITICAL Requirements) |
| stdout is not a terminal | Use `codex exec`, not `codex` |
| Not authenticated | Run `codex login` |

See `references/troubleshooting.md` for details.

## Quick Examples

### Example 1: Design with Codex, Implement with Claude

**User**: "Use Codex to design a REST API for a blog system"

**Codex executes**:
```bash
codex exec -m gpt-5.2-codex -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "Design a REST API for a blog system"
```

**Codex provides**: Architecture design, endpoint specs, data models

**Then user tells Claude**: "Implement the user authentication endpoint based on Codex's design"

---

### Example 2: Resume Session

**User**: "Continue with that API - add error handling"

**Codex executes**:
```bash
codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true resume --last "Add comprehensive error handling to the API"
```

**Result**: Builds on previous API design with full context

---

See `references/command-patterns.md` for complete workflow examples and patterns.

## Best Practices

1. **Codex for thinking**: Design, review, debug analysis (read-only)
2. **Claude for doing**: Implementation, refactoring, file modifications
3. **Be specific**: "Design distributed cache strategy" > "Help with caching"
4. **Use sessions**: Build context over multiple interactions


## Additional Resources

- `references/command-patterns.md` - Design → Implementation workflow patterns
- `references/session-workflows.md` - Session continuation and persistence
- `references/troubleshooting.md` - Error solutions and troubleshooting
- `references/codex-config.md` - Complete configuration reference
- `references/codex-help.md` - CLI flags and commands
- `references/advanced-patterns.md` - Advanced options (web search, reasoning control)
