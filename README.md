# cc-skill-codex

A Claude Code **plugin** that provides a skill for seamless OpenAI Codex CLI integration. The skill uses whatever model Codex CLI is configured to default to — no model is pinned by the skill itself.

**Positioning**: Codex is a peer coding agent. Strongest fit is **adversarial / steerable code review**; also useful for standard review, deep design analysis, debugging investigations, and delegated tasks. Both Codex and Claude can read and write code — pick by task fit, not by role.

**Codex CLI Version**: v0.114.0+

## What is this?

**cc-skill-codex** is a Claude Code **plugin** that contains the **codex skill**. When you install this plugin, you get access to the skill that enables Codex CLI integration.

- **Marketplace name**: `cc-skill-codex-marketplace`
- **Plugin name**: `cc-skill-codex`
- **Full plugin identifier**: `cc-skill-codex@cc-skill-codex-marketplace`
- **Skill name**: `codex`
- **Installation**: Via Claude Code marketplace (installs the plugin, which includes the skill)

## Repository Structure

```
cc-skill-codex/                  # Plugin root
├── .claude-plugin/              # Plugin metadata
│   ├── plugin.json             # Plugin configuration
│   └── marketplace.json        # Marketplace configuration
├── README.md                    # This file - installation and usage guide
├── LICENSE                      # Apache 2.0 license
└── skills/                      # Skills provided by this plugin
    └── codex/                  # The "codex" skill
        └── SKILL.md            # Main skill definition (loaded by Claude Code)
```

**How it works**:
1. You add the **marketplace** (`cc-skill-codex-marketplace`) from GitHub
2. You install the **plugin** (`cc-skill-codex`) from the marketplace
3. The plugin provides the **skill** (`codex`)
4. Claude Code loads `skills/codex/SKILL.md` when the skill is invoked
5. `skills/codex/SKILL.md` is the primary maintained documentation surface

---

## Installation in Claude Code

### Prerequisites

1. **Codex CLI** installed and authenticated:
   ```bash
   codex --version  # v0.114+
   codex login
   ```

2. **Claude Code** installed and running

### Installation Methods

#### Method 1: Interactive Menu (Recommended)

1. Add the marketplace to Claude Code:
   ```bash
   /plugin marketplace add wywwzjj/cc-skill-codex
   ```

2. Open plugin management:
   ```bash
   /plugin
   ```

3. Select **"Browse Plugins"** to view available plugins

4. Find and select **cc-skill-codex**

5. Choose the installation option

#### Method 2: Direct Command

```bash
# 1. Add the marketplace
/plugin marketplace add wywwzjj/cc-skill-codex

# 2. Install the plugin
/plugin install cc-skill-codex@cc-skill-codex-marketplace
```

### Verify Installation

After installation, verify the skill is working:

```
> Use Codex to design a binary search tree in Rust
```

The skill will invoke Codex CLI using whatever model your Codex CLI is configured to default to.

---

## Step-by-Step Tutorial

### Step 1: Install Prerequisites

```bash
# Check if Codex CLI is installed
codex --version  # Requires v0.114+

# If not installed, follow OpenAI's installation instructions
# https://developers.openai.com/codex/cli/installation

# Authenticate with your OpenAI account
codex login
```

### Step 2: Add the Marketplace

Add the GitHub marketplace to Claude Code:

```bash
/plugin marketplace add wywwzjj/cc-skill-codex
```

This registers the marketplace so Claude Code knows where to find the plugin.

### Step 3: Install the Plugin

**Option A: Interactive Menu (Recommended)**

1. Open plugin management:
   ```bash
   /plugin
   ```

2. Select "Browse Plugins"

3. Find "cc-skill-codex" and install it

**Option B: Direct Command**

```bash
/plugin install cc-skill-codex@cc-skill-codex-marketplace
```

**Note**: The full identifier is `cc-skill-codex@cc-skill-codex-marketplace` where:
- `cc-skill-codex` = plugin name
- `cc-skill-codex-marketplace` = marketplace name (from marketplace.json)

### Step 4: Verify Installation

Check the plugin is installed:
```bash
/plugin
```

Select "Manage Plugins" to see cc-skill-codex in your list.

### Step 5: Use Codex for Adversarial / Steerable Review (Flagship)

The strongest reason to reach for Codex: pressure-test a design rather than nitpick lines.

**Adversarial review request**:
```
> Use Codex to challenge the caching/retry design in src/api/client.ts — pressure-test for race conditions and rollback gaps
```

Codex will:
1. Execute a read-only `codex exec` with a steered prompt that explicitly asks it to challenge the design, surface hidden assumptions, and identify failure modes
2. Return concrete risks (race conditions, data loss paths, auth weaknesses, reliability cliffs) with reasoning
3. Often suggest where a different design would have been safer or simpler

**Why this is the flagship**: an independent agent challenging your design catches what an in-the-flow reviewer misses. Steer it at a specific risk area for best results — generic "review this" is much weaker than "challenge whether retries belong in this layer".

### Step 6: Use Codex for Standard Code Review or Design Analysis

**Standard review request**:
```
> Use Codex to review auth.py for security issues
```

**Design analysis request**:
```
> Use Codex to analyze approaches for a multi-tenant rate limiter
```

Codex returns its findings; you (or Claude) decide what to do with them. Codex can also be delegated the fix directly when appropriate — see Step 8.

### Step 7: Continue a Session

**Follow-up request** (continuing the adversarial review from Step 5):
```
> Continue that review — also pressure-test the rollback path under partial failure
```

Codex will:
1. Resume the prior session **by ID** (not `--last`): `codex exec resume <SESSION_ID> "Pressure-test the rollback path under partial failure" 2>/tmp/codex_stderr.log`
2. Resume with full context from the previous session — same target code, same prior reasoning
3. Build on what was already challenged rather than starting over

**Why ID-based resume matters**: `--last` resumes the globally most recent Codex session and races with any other Codex call (parallel reviews, the user invoking Codex directly, background tasks). The skill captures the session ID at the end of each new run by appending `&& echo "SESSION_ID=$(grep 'session id:' /tmp/codex_stderr.log | tail -1 | awk '{print $NF}')"` — that ID stays in Claude's context for follow-ups. `--last` is reserved as a fallback for when the ID is genuinely unrecoverable.

**Why session continuation matters**: Codex sessions persist across Claude Code restarts. Multi-day reviews and investigations stay coherent — you can resume days later with full prior context.

### Step 8: Debug Investigation or Delegated Task

**Debug investigation** (read-only):
```
> Use Codex to investigate why my queue implementation deadlocks under high concurrency
```

Codex will trace the bug end-to-end and propose root cause + fix. You can then apply the fix yourself (with Claude) for tight control.

**Delegated task** (workspace-write — Codex actually writes the patch):
```
> Have Codex fix the deadlock in queue.py — apply the smallest safe patch
```

When the user clearly says "have Codex fix" or "let Codex patch", invoke with `-s workspace-write` and let Codex own the change.

**Tradeoff**: read-only investigation gives Claude/you full control over the patch; delegated workspace-write is faster but Codex picks the implementation. Pick by how much you trust the local context vs. value the speed.

---

## Quick Tips

### Workflow Pattern
- **Adversarial / steerable review** is the flagship — challenge designs, pressure-test tradeoffs, find hidden risks
- **Default sandbox is `read-only`** — most invocations are analysis, review, or investigation
- **Use `-s workspace-write` only when delegating a fix** — when the user explicitly says "have Codex fix it"
- **Pick by task fit, not by role** — both Codex and Claude can read and write code

### Triggering the Skill
- **Explicit**: "Use Codex to challenge...", "Use Codex to pressure-test...", "Use Codex to review..."
- **Keywords**: Mention "Codex" to explicitly trigger the skill
- **Steered**: For adversarial reviews, name the risk area — "challenge the retry design", "look for race conditions in the connection pool". Generic asks underperform focused ones.

### Model Usage
- **Model**: The skill does not pin a model — Codex CLI's current default is used (whichever model your installed Codex version ships with). To override, pass `-m <model>`.
- **Reasoning effort**: New sessions use `model_reasoning_effort=high` by default; resumed sessions inherit the original session settings unless explicitly overridden.

### Session Continuation
- **Keywords**: "continue", "resume", "add to that", "keep going"
- **Persistence**: Sessions survive Claude Code restarts
- **Long-term context**: Resume projects days or weeks later with full history

### Common Use Cases
| Task | Use Codex? | Example |
|------|-----------|---------|
| **Adversarial / steerable review** | ✅ Strongest fit | "Challenge the caching design — find race conditions" |
| Standard code review | ✅ Yes | "Use Codex to review auth.py for security" |
| Design / architecture analysis | ✅ Yes | "Use Codex to analyze rate-limiter approaches" |
| Debug investigation | ✅ Yes | "Use Codex to trace why this deadlocks" |
| Delegated fix / refactor | ✅ When delegated explicitly | "Have Codex apply the smallest safe patch" |
| Quick edit you can do yourself | ❌ Skip | Just have Claude do it |

---

## Documentation

For the plugin docs, see:
- `skills/codex/SKILL.md` - Main skill definition, command patterns, and common failure guidance

---

**License**: Apache 2.0
**Version**: 3.2.0
**Codex CLI**: v0.114+
**Positioning**: Codex as a peer coding agent — flagship use case is adversarial / steerable code review.
