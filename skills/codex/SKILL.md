---
name: codex
description: Invoke Codex CLI for high-reasoning tasks requiring GPT-5.1 capabilities. Use when user mentions "Codex", requests design/architecture, code review, debug analysis, or algorithm design. Codex = Brain (thinking), Claude = Hands (implementation). Supports session continuation for long-term projects.
---

# cc-skill-codex: Codex CLI Integration for Claude Code

---

## ⚠️ CRITICAL: Always Use `codex exec`

**MUST USE**: `codex exec` for ALL Codex CLI invocations in Claude Code.

❌ **NEVER USE**: `codex` (interactive mode) - will fail with "stdout is not a terminal"
✅ **ALWAYS USE**: `codex exec` (non-interactive mode)

**Examples:**
- ✅ `codex exec -m gpt-5.1 "prompt"` (CORRECT)
- ✅ `codex exec resume --last "continue prompt"` (CORRECT - must include prompt)
- ✅ `echo "prompt" | codex exec resume --last -` (CORRECT - stdin with -)
- ❌ `codex exec resume --last` (WRONG - missing prompt, will error)
- ❌ `codex -m gpt-5.1 "prompt"` (WRONG - interactive mode fails)
- ❌ `codex resume --last "prompt"` (WRONG - must use `codex exec`)

**Why?** Claude Code's bash environment is non-terminal/non-interactive. Only `codex exec` works in this environment.

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
- User requests "GPT-5.1" capabilities
- User wants to continue a previous Codex session

## How It Works

### Recommended Approach

**Primary use case: High-level reasoning (read-only)**
```bash
codex exec -m gpt-5.1 -s read-only \
  -c model_reasoning_effort=high \
  "<design/review/debug prompt>"
```

**Default to read-only** - let Claude handle actual implementation.

Use workspace-write only when user explicitly requests Codex to modify files (rare).

### Default Configuration

All Codex invocations use these defaults unless user specifies otherwise:

| Parameter | Default Value | CLI Flag | Notes |
|-----------|---------------|----------|-------|
| Model | `gpt-5.1` | `-m gpt-5.1` | General reasoning tasks |
| Model (code editing) | `gpt-5.1-codex` | `-m gpt-5.1-codex` | Code editing tasks |
| Sandbox | `read-only` | `-s read-only` | Safe default (general tasks) |
| Sandbox (code editing) | `workspace-write` | `-s workspace-write` | Allows file modifications |
| Reasoning Effort | `high` | `-c model_reasoning_effort=high` | Maximum reasoning capability |
| Verbosity | `medium` | `-c model_verbosity=medium` | Balanced output detail |
| Web Search | `enabled` | `--enable web_search_request` | Access to up-to-date information |

### Common Flags

- `-m`: Model (`gpt-5.1`, `gpt-5.1-codex`)
- `-s`: Sandbox (`read-only`, `workspace-write`, `danger-full-access`)
- `-c`: Config (e.g., `model_reasoning_effort=high`)
- `-i`: Attach images
- `--enable web_search_request`: Enable web search (for `codex exec`)
- `--full-auto`: workspace-write + on-request approval

**Note**: Use `--enable web_search_request` with `codex exec`, not `--search` (which only works in interactive `codex` mode).

See `references/codex-help.md` for complete flag list.

## Session Continuation

**Key Advantage**: Codex sessions persist across Claude Code restarts - unlike Claude's context, Codex maintains full conversation history days or weeks later.

### When to Resume

Detect continuation when user says:
- "continue", "resume", "keep going", "add to that"
- References previous Codex work
- Iterative development on same task

### How to Resume

**IMPORTANT**: Prompt is **required**.

```bash
# ✅ Resume with prompt (required)
codex exec resume --last "Add error handling"

# ✅ Pipe via stdin
echo "Continue implementation" | codex exec resume --last -

# ❌ WRONG - will fail with "No prompt provided"
codex exec resume --last
```

### New Session vs. Resume

| Scenario | Command |
|----------|---------|
| New independent request | `codex exec -m gpt-5.1 "prompt"` |
| User says "fresh start" | `codex exec -m gpt-5.1 "prompt"` |
| User says "continue" | `codex exec resume --last "prompt"` |
| Building on previous work | `codex exec resume --last "prompt"` |

**Sessions auto-save** - no manual tracking needed. See `references/session-workflows.md` for detailed examples and workflows.

## Error Handling

When errors occur, return clear, actionable messages:

### Common Errors

**No Prompt Provided**
```
Error: No prompt provided
Fix: codex exec resume --last "your prompt here"
```

**Not Authenticated**
```
Error: Not authenticated with Codex
Fix: Run 'codex login' to authenticate
```

**Command Not Found**
```
Error: Codex CLI not found
Fix: Install Codex CLI - check with 'codex --version'
```

**"stdout is not a terminal"**
```
Error: stdout is not a terminal
Fix: Use 'codex exec', not 'codex'
```

See `references/troubleshooting.md` for complete error reference, solutions, and troubleshooting workflows.

## Quick Examples

### Example 1: Design with Codex, Implement with Claude

**User**: "Use Codex to design a REST API for a blog system"

**Codex executes**:
```bash
codex exec -m gpt-5.1 -s read-only \
  -c model_reasoning_effort=high \
  "Design a REST API for a blog system"
```

**Codex provides**: Architecture design, endpoint specs, data models

**Then user tells Claude**: "Implement the user authentication endpoint based on Codex's design"

---

### Example 2: Resume Session

**User**: "Continue with that API - add error handling"

**Codex executes**:
```bash
codex exec resume --last "Add comprehensive error handling to the API"
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
