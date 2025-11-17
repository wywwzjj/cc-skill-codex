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
codex exec -m gpt-5.1 -s read-only \
  -c model_reasoning_effort=high \
  --enable web_search_request \
  "Research latest distributed system patterns for microservices in 2025"
```

**Use for**: Architecture research, security best practices, tech comparisons

---

## Reasoning Control

### High Reasoning (Default)
```bash
codex exec -c model_reasoning_effort=high "Complex design problem"
```
**Use for**: Complex architecture, algorithm design, security analysis

### Medium Reasoning
```bash
codex exec -c model_reasoning_effort=medium "Standard review task"
```
**Use for**: Standard code reviews, moderate complexity

### Low Reasoning
```bash
codex exec -c model_reasoning_effort=low "Quick sanity check"
```
**Use for**: Quick syntax checks, simple questions

**Default is high** - only lower if you need faster responses for simple tasks.

---

## Verbosity Control

### High Verbosity
```bash
codex exec -c model_verbosity=high "Explain this algorithm in detail"
```
**Output**: Comprehensive, detailed explanations

### Medium Verbosity (Default)
```bash
codex exec -c model_verbosity=medium "Review this code"
```
**Output**: Balanced detail

### Low Verbosity
```bash
codex exec -c model_verbosity=low "Quick code review"
```
**Output**: Concise, focused feedback

---

## Working Directory

### Change Working Directory
```bash
codex exec -C ./backend "Review the API architecture in this directory"
```

**Use when**: Working with specific subdirectories

---

## Combined Example

### Research + Design
```bash
codex exec -m gpt-5.1 -s read-only \
  -c model_reasoning_effort=high \
  -c model_verbosity=high \
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
| `-c model_reasoning_effort` | `high/medium/low` | Complexity of reasoning |
| `-c model_verbosity` | `high/medium/low` | Detail level in output |
| `--enable web_search_request` | flag | Need latest information |
| `-C <dir>` | directory path | Work in specific directory |

---

## Remember

**Codex = Think (read-only)**
- Design, plan, review, debug analysis

**Claude = Do (implementation)**
- Code, refactor, fix, implement

Only use `workspace-write` with Codex if you have a specific reason (rare).
