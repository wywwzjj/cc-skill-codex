# Session Continuation with Codex

---

## Why Use Codex Sessions?

**Key Advantage**: Codex sessions **persist across Claude Code restarts**.

Unlike Claude's conversation context (which resets when you close Claude Code), Codex sessions are saved and can be resumed days or weeks later with full context.

**Best for:**
- Long-term projects spanning multiple days
- Complex work you want to pause and resume later
- Projects needing separate context from Claude conversations

**Not needed for:**
- Quick tasks within a single Claude Code session
- Simple back-and-forth within current conversation

---

## ⚠️ CRITICAL: Always Use `codex exec`

**ALL commands in this document use `codex exec` - this is mandatory in Claude Code.**

❌ **NEVER**: `codex resume ...` (will fail with "stdout is not a terminal")
✅ **ALWAYS**: `codex exec resume ...` (correct non-interactive mode)

---

## Example 1: Starting a Long-Term Project

### Initial Request
**User**: "Use Codex to help me design a queue data structure in Python"

**Skill Executes**:
```bash
codex exec -m gpt-5.1 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  -c model_reasoning_summary=concise \
  "Help me design a queue data structure in Python"
```

**Codex Response**: Provides queue design with multiple approaches.

**Session Auto-Saved**: Codex CLI saves this session automatically.

---

### Follow-Up Request (Same Session)
**User**: "Continue with Codex - add thread-safety to the queue. Please ensure it handles concurrent access properly and includes proper locking mechanisms."

**Skill Detects**: "Continue with Codex" keyword

**Skill Executes** (using heredoc for multi-line prompt):
```bash
codex exec -m gpt-5.1 resume --last <<'EOF'
Add thread-safety to the queue. Please ensure it handles concurrent access properly and includes proper locking mechanisms.
EOF
```

**Note**: Always specify `-m gpt-5.1` (before `resume`) to match original session model. For single-line: `codex exec -m gpt-5.1 resume --last "prompt"`

**Codex Response**: Resumes previous session, maintains context about the queue design, and adds thread-safety implementation building on the previous discussion.

**Context Maintained**: All previous conversation history is available to Codex.

---

## Example 2: Multi-Turn Iterative Development

### Turn 1: Initial Design
**User**: "Design a REST API for a blog system"

```bash
codex exec -m gpt-5.1 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  -c model_reasoning_summary=concise \
  "Design a REST API for a blog system"
```

**Output**: API endpoint design, resource modeling, etc.

---

### Turn 2: Add Authentication
**User**: "Add authentication to that API design"

**Skill Executes**:
```bash
codex exec -m gpt-5.1 resume --last "Add authentication to the API"
```

**Output**: Codex continues from previous API design and adds JWT/OAuth authentication strategy.

---

### Turn 3: Add Error Handling
**User**: "Now add comprehensive error handling"

**Skill Executes**:
```bash
codex exec -m gpt-5.1 resume --last "Add comprehensive error handling"
```

**Output**: Codex builds on previous API + auth design and adds error handling patterns.

---

### Turn 4: Implementation
**User**: "Implement the user authentication endpoint"

**Skill Executes**:
```bash
codex exec -m gpt-5.1 resume --last "Implement the user authentication endpoint"
```

**Output**: Codex uses all previous context to implement the auth endpoint with full understanding of the API design.

**Result**: After 4 turns, you have a complete API with design, auth, error handling, and initial implementation - all with maintained context.

---

## Example 3: Explicit Resume Command

### When to Use Interactive Picker

If you have multiple Codex sessions and want to choose which one to continue:

**User**: "Show me my Codex sessions and let me pick which to resume"

**Manual Command** (run outside skill):
```bash
codex exec -m gpt-5.1 resume --last "your prompt"
```

This opens an interactive picker showing:
```
Recent Codex Sessions:
1. Queue data structure design (30 minutes ago)
2. REST API for blog system (2 hours ago)
3. Binary search tree implementation (yesterday)

Select session to resume:
```

---

## Example 4: Resuming After Claude Code Restart (KEY USE CASE)

### Scenario
1. **Day 1**: You worked on a queue design with Codex
2. **Day 1 Evening**: Closed Claude Code (Claude's context is lost)
3. **Day 3**: Reopened Claude Code - Claude has no memory of the queue work

### Resume Request
**User**: "Resume my last Codex session about the queue implementation"

**Skill Executes**:
```bash
codex exec -m gpt-5.1 resume --last "Continue the queue implementation"
```

**Result**: Codex resumes the queue session with **full context from Day 1**, even though Claude Code was closed and reopened.

**Why This Matters**: This is Codex's killer feature - **persistent long-term context** across restarts that Claude cannot provide.

---

## Continuation Keywords

The skill detects continuation requests when you use phrases like:

- "Continue with that"
- "Resume the previous session"
- "Keep going"
- "Add to that"
- "Now add X" (implies building on previous)
- "Continue where we left off"
- "Follow up on that"

---

## Decision Tree: New Session vs. Resume

```
User makes request
│
├─ Contains continuation keywords?
│  │
│  ├─ YES → Use `codex exec -m gpt-5.1 resume --last`
│  │
│  └─ NO → Check context
│     │
│     ├─ References previous Codex work?
│     │  │
│     │  ├─ YES → Use `codex exec -m gpt-5.1 resume --last`
│     │  │
│     │  └─ NO → New session: `codex exec -m ... "prompt"`
│
└─ User explicitly says "new" or "fresh"?
   │
   └─ YES → Force new session even if continuation keywords present
```

---

## Session History Management

### Automatic Save
- Every Codex session is automatically saved by Codex CLI
- No manual session ID tracking needed
- Sessions persist across:
  - Claude Code restarts
  - Terminal sessions
  - System reboots

### Accessing History
```bash
# Resume most recent (recommended for skill)
codex exec -m gpt-5.1 resume --last "your prompt"

# Interactive picker (manual use)
codex exec -m gpt-5.1 resume --last "your prompt"

# List sessions (manual use)
codex list
```

---

## Best Practices

### 1. Use Clear Continuation Language

**Good**:
- "Continue with that queue implementation - add unit tests"
- "Resume the API design session and add rate limiting"

**Less Clear**:
- "Add tests" (ambiguous - new or continue?)
- "Rate limiting" (no continuation context)

### 2. Build Incrementally

Start with high-level design, then iterate:
1. Design (new session)
2. Add feature A (resume)
3. Add feature B (resume)
4. Implement (resume with full context)

### 3. Leverage Context Accumulation

Each resumed session has ALL previous context:
- Design decisions
- Trade-offs discussed
- Code patterns chosen
- Error handling approaches

This allows Codex to provide increasingly sophisticated, context-aware assistance.

---

## Troubleshooting

### "No previous sessions found"

**Cause**: Codex CLI history is empty (no prior sessions)

**Fix**: Start a new session first:
```bash
codex exec -m gpt-5.1"Design a queue"
```

Then subsequent "continue" requests will work.

---

### Session Not Resuming Correctly

**Symptoms**: Resume works but context seems lost

**Possible Causes**:
- Multiple sessions mixed together
- User explicitly requested "fresh start"

**Fix**: Use interactive picker to select correct session:
```bash
codex exec -m gpt-5.1 resume --last "your prompt"
```

---

### Multiple Sessions Confusion

**Scenario**: Working on two projects, want to resume specific one

**Solution**:
1. Be explicit: "Resume the queue design session" (skill will use --last)
2. Or manually: `codex exec -m gpt-5.1 resume --last "your prompt"` (or `codex exec resume <session-id>`) → pick correct session

---

## Next Steps

- **Advanced config**: See [advanced-config.md](./advanced-config.md)
- **Basic examples**: See [basic-usage.md](./basic-usage.md)
- **Full docs**: See [../SKILL.md](../SKILL.md)
