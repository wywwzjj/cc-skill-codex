# Advanced Codex Options

---

## Do You Need This?

**Probably not.** The patterns in `command-patterns.md` cover 95% of use cases.

**Read this only if you need:**
- Web search for latest info
- Custom reasoning levels
- Working directory control
- Specific config overrides

**Remember**: Codex is for **thinking** (design, review, debug), Claude is for **doing** (implementation).

---

## Web Search Integration

**Note**: As of v0.101.0, `web_search_request` is **deprecated**. Web search capabilities may be handled differently in newer versions.

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

## Working Directory

### Change Working Directory
```bash
codex exec -C ./backend -c hide_agent_reasoning=true "Review the API architecture in this directory"
```

**Use when**: Working with specific subdirectories

---

## Combined Example

### Design with Directory Context
```bash
codex exec -m gpt-5.3-codex -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  -C ./backend \
  "Analyze the current authentication patterns and design an improved auth system for this project"
```

**This combines**:
- High reasoning for design
- Specific working directory

---

## Quick Reference

| Flag | Values | Use Case |
|------|--------|----------|
| `-c model_reasoning_effort` | `xhigh/high/medium/low/minimal` | Complexity of reasoning |
| `-c hide_agent_reasoning` | `true` | **IMPORTANT**: Hide thinking output to reduce context |
| `-C <dir>` | directory path | Work in specific directory |

> **Note**: The `--search` flag has been removed as of v0.101.0. `web_search_request` is deprecated.

---

## Remember

**Codex = Think (read-only)**
- Design, plan, review, debug analysis

**Claude = Do (implementation)**
- Code, refactor, fix, implement

Only use `workspace-write` with Codex if you have a specific reason (rare).
