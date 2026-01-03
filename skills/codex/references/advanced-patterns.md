# Advanced Codex Options

---

## Do You Need This?

**Probably not.** The patterns in `command-patterns.md` cover 95% of use cases.

**Read this only if you need:**
- Web search for latest info
- Custom reasoning/verbosity levels
- Working directory control
- Specific config overrides

**Remember**: Codex is for **thinking** (design, review, debug), Claude is for **doing** (implementation).

---

## Web Search Integration

### When to Use
Need latest information, best practices, or recent developments.

### Example: Research Latest Patterns
```bash
codex exec -m gpt-5.2-codex -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  --enable web_search_request \
  "Research latest distributed system patterns for microservices in 2025"
```

**Use for**: Architecture research, security best practices, tech comparisons

---

## Reasoning Control

### XHigh Reasoning (Maximum)
```bash
codex exec -c model_reasoning_effort=xhigh -c hide_agent_reasoning=true "Extremely complex problem"
```
**Use for**: Most complex architecture, deep algorithm design, thorough security analysis

### High Reasoning (Default)
```bash
codex exec -c model_reasoning_effort=high -c hide_agent_reasoning=true "Complex design problem"
```
**Use for**: Complex architecture, algorithm design, security analysis

### Medium Reasoning
```bash
codex exec -c model_reasoning_effort=medium -c hide_agent_reasoning=true "Standard review task"
```
**Use for**: Standard code reviews, moderate complexity

### Low Reasoning
```bash
codex exec -c model_reasoning_effort=low -c hide_agent_reasoning=true "Quick sanity check"
```
**Use for**: Quick syntax checks, simple questions

### Minimal Reasoning
```bash
codex exec -c model_reasoning_effort=minimal -c hide_agent_reasoning=true "Simple task"
```
**Use for**: Very simple tasks, fastest response

**Default is high** - adjust based on task complexity.

---

## Verbosity Control

### High Verbosity
```bash
codex exec -c model_verbosity=high -c hide_agent_reasoning=true "Explain this algorithm in detail"
```
**Output**: Comprehensive, detailed explanations

### Medium Verbosity (Default)
```bash
codex exec -c model_verbosity=medium -c hide_agent_reasoning=true "Review this code"
```
**Output**: Balanced detail

### Low Verbosity
```bash
codex exec -c model_verbosity=low -c hide_agent_reasoning=true "Quick code review"
```
**Output**: Concise, focused feedback

---

## Working Directory

### Change Working Directory
```bash
codex exec -C ./backend -c hide_agent_reasoning=true "Review the API architecture in this directory"
```

**Use when**: Working with specific subdirectories

---

## Combined Example

### Research + Design
```bash
codex exec -m gpt-5.2-codex -s read-only \
  -c model_reasoning_effort=high \
  -c model_verbosity=high \
  -c hide_agent_reasoning=true \
  --enable web_search_request \
  -C ./backend \
  "Research latest authentication patterns (2025) and design an auth system for this project"
```

**This combines**:
- Web search for latest info
- High reasoning for design
- High verbosity for detailed output
- Specific working directory

---

## Quick Reference

| Flag | Values | Use Case |
|------|--------|----------|
| `-c model_reasoning_effort` | `xhigh/high/medium/low/minimal` | Complexity of reasoning |
| `-c model_verbosity` | `high/medium/low` | Detail level in output |
| `-c hide_agent_reasoning` | `true` | **IMPORTANT**: Hide thinking output to reduce context |
| `-C <dir>` | directory path | Work in specific directory |

> **Note**: `--search` flag is only available for interactive `codex` mode, NOT for `codex exec`.

---

## Remember

**Codex = Think (read-only)**
- Design, plan, review, debug analysis

**Claude = Do (implementation)**
- Code, refactor, fix, implement

Only use `workspace-write` with Codex if you have a specific reason (rare).
