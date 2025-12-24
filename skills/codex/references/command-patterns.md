# Codex Usage Patterns: Design → Implementation Workflow

---

## Recommended Workflow

**Codex = Brain (High-Level Reasoning)**
- Architecture design
- System planning
- Code review
- Debugging analysis
- Trade-off evaluation

**Claude = Hands (Implementation)**
- Actual coding
- File modifications
- Refactoring
- Feature implementation

**Why this works**: Codex (GPT-5.2) excels at deep reasoning, while Claude Code's integration makes implementation seamless.

---

## ⚠️ CRITICAL: Always Use `codex exec`

**ALL commands use `codex exec` - mandatory in Claude Code.**

❌ **NEVER**: `codex -m ...` (will fail)
✅ **ALWAYS**: `codex exec -m ...` (correct)

---

## Pattern 1: Architecture Design with Codex

### User Request
"Use Codex to design a REST API architecture for a blog system"

### Command
```bash
# Use heredoc for multi-line prompts
codex exec -m gpt-5.2 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true <<'EOF'
Design a REST API architecture for a blog system. Focus on:
- Resource modeling
- Endpoint design
- Authentication strategy
- Scalability considerations
EOF
```

### Codex Output
- High-level architecture diagram
- Endpoint specifications
- Data models
- Trade-offs and recommendations

### Next Step
**You tell Claude**: "Implement the user authentication endpoint based on Codex's design"

---

## Pattern 2: Code Review with Codex

### User Request
"Use Codex to review this authentication code for security issues"

### Command
```bash
codex exec -m gpt-5.2 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "Review this authentication code for:\n\
  - Security vulnerabilities\n\
  - Best practices violations\n\
  - Potential improvements\n\
  \n\
  [paste code here]"
```

### Codex Output
- Detailed security analysis
- Vulnerability identification
- Improvement recommendations

### Next Step
**You tell Claude**: "Fix the security issues identified by Codex in auth.py:45-67"

---

## Pattern 3: Debugging Strategy with Codex

### User Request
"Use Codex to help debug why my queue implementation deadlocks under high concurrency"

### Command
```bash
codex exec -m gpt-5.2 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "Analyze this queue implementation for deadlock issues:\n\
  - Identify potential race conditions\n\
  - Explain the deadlock scenario\n\
  - Suggest debugging approach\n\
  \n\
  [paste code here]"
```

### Codex Output
- Root cause analysis
- Deadlock scenario explanation
- Debugging strategy
- Fix recommendations

### Next Step
**You tell Claude**: "Apply the fix Codex suggested: add lock ordering at lines 23-45"

---

## Pattern 4: Planning Complex Features

### User Request
"Use Codex to plan how to add caching layer to this system"

### Command
```bash
codex exec -m gpt-5.2 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "Plan a caching layer for this system:\n\
  - Cache strategy (where, what, when)\n\
  - Invalidation approach\n\
  - Integration points\n\
  - Migration plan\n\
  \n\
  [paste current architecture]"
```

### Codex Output
- Caching strategy
- Step-by-step implementation plan
- Risk assessment

### Next Step
**You tell Claude**: "Implement phase 1 of the caching plan: add Redis client wrapper"

---

## Pattern 5: Algorithm Design

### User Request
"Use Codex to design an optimal algorithm for distributed consensus"

### Command
```bash
codex exec -m gpt-5.2 -s read-only \
  -c model_reasoning_effort=high \
  -c hide_agent_reasoning=true \
  "Design a distributed consensus algorithm for:\n\
  - Network: 5-10 nodes\n\
  - Requirement: Strong consistency\n\
  - Constraint: Network partitions possible\n\
  \n\
  Provide:\n\
  - Algorithm choice and rationale\n\
  - Step-by-step protocol\n\
  - Edge case handling"
```

### Codex Output
- Algorithm selection (e.g., Raft)
- Detailed protocol steps
- Edge case analysis

### Next Step
**You tell Claude**: "Implement the leader election phase of the Raft algorithm"

---

## Quick Reference: When to Use Codex

| Scenario | Use Codex? | Example |
|----------|-----------|---------|
| "Design REST API" | ✅ Yes | Architecture, planning |
| "Review security" | ✅ Yes | Analysis, recommendations |
| "Debug deadlock" | ✅ Yes | Root cause analysis |
| "Plan caching" | ✅ Yes | Strategy, roadmap |
| "Implement feature" | ❌ No | Let Claude do it |
| "Refactor code" | ❌ No | Let Claude do it |
| "Fix bug" | ❌ No | Let Claude do it (after Codex analyzes) |

---

## Best Practices

### 1. Always Use read-only Mode
```bash
# ✅ Correct - Codex for thinking, not doing
codex exec -s read-only -c hide_agent_reasoning=true "Design the system"

# ❌ Avoid - Let Claude handle implementation
codex exec -s workspace-write "Implement the system"
```

### 2. Be Specific in Requests
**Good**: "Design a caching strategy with Redis for user session data, considering 1M DAU"
**Vague**: "Help with caching"

### 3. Feed Codex Context
Include relevant code, architecture diagrams, or requirements in your prompt.

### 4. Iterate with Claude
1. Get Codex's design/analysis
2. Implement with Claude
3. Use Codex to review Claude's implementation
4. Refine with Claude

---

## Example Full Workflow

**Step 1**: "Use Codex to design a message queue system"
→ Codex provides architecture design

**Step 2**: "Claude, implement the Queue class based on Codex's design"
→ Claude writes the code

**Step 3**: "Use Codex to review Claude's queue implementation"
→ Codex finds a potential race condition

**Step 4**: "Claude, fix the race condition at line 45 as Codex suggested"
→ Claude applies the fix

**Step 5**: "Use Codex to analyze the performance characteristics"
→ Codex provides complexity analysis

---

## Next Steps

- **Session management**: See `session-workflows.md` for long-term projects
- **Advanced options**: See `advanced-patterns.md` if needed (most users don't need it)
