# cc-skill-codex

A dual-direction peer-agent marketplace: **two plugins** that let Claude Code and OpenAI Codex CLI call each other as peer coding agents. Neither skill pins a model — each uses whatever the callee CLI is configured to default to.

| Plugin | Direction | Install into | Skill |
|--------|-----------|--------------|-------|
| `cc-skill-codex` | Claude → Codex (`codex exec`) | Claude Code | `codex` |
| `codex-skill-claude` | Codex → Claude (`claude -p`) | Codex CLI | `claude` |

**Positioning** (both directions): the callee is a peer coding agent. Strongest fit is **adversarial / steerable code review**; also useful for standard review, deep design analysis, debugging investigations, and delegated tasks. Both agents can read and write code — pick by task fit, not by role.

**Verified versions**: Codex CLI v0.142.2 (skill commands) / v0.145.0 (plugin install); Claude Code v2.1.206.

## What is this?

One repository serves both ecosystems: Codex CLI's plugin system reads Claude's `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` directly, so the same marketplace installs into either agent. The two directions are **separate plugins** on purpose — an installed plugin loads *all* its skills into the host agent, so bundling both skills in one plugin would give each agent a wrong-direction skill.

- **Marketplace name**: `cc-skill-codex-marketplace`
- **For Claude Code users**: install `cc-skill-codex@cc-skill-codex-marketplace` → get the `codex` skill
- **For Codex CLI users**: install `codex-skill-claude@cc-skill-codex-marketplace` → get the `claude` skill

> Known limitation: both hosts can *see* both plugins in the marketplace listing — nothing enforces the pairing. Installing the wrong direction (e.g. `codex-skill-claude` into Claude Code) gives the host a skill for calling *itself* — unsupported, and a self-call could recurse or burn tokens pointlessly. Install only your own direction.

## Repository Structure

```
cc-skill-codex-marketplace/          # Marketplace root (served to both agents)
├── .claude-plugin/
│   └── marketplace.json             # Marketplace configuration: lists both plugins
├── plugins/
│   ├── cc-skill-codex/              # Claude → Codex plugin
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/codex/
│   │       ├── SKILL.md             # Loaded by Claude Code
│   │       └── scripts/codex-ask.sh # Wrapper: answer + SESSION_ID + DETAILS
│   └── codex-skill-claude/          # Codex → Claude plugin
│       ├── .claude-plugin/plugin.json
│       └── skills/claude/
│           ├── SKILL.md             # Loaded by Codex CLI
│           └── scripts/claude-ask.sh # Wrapper: answer + SESSION_ID + DETAILS
├── README.md                        # This file - installation and usage guide
└── LICENSE                          # Apache 2.0 license
```

**How it works**:
1. You add the **marketplace** (`cc-skill-codex-marketplace`) from GitHub — in Claude Code *or* Codex CLI
2. You install the **plugin for your direction** (`cc-skill-codex` or `codex-skill-claude`)
3. The plugin provides the **skill** (`codex` or `claude`)
4. The host agent loads the plugin's `SKILL.md` when the skill is invoked
5. Each `SKILL.md` is the primary maintained documentation surface for its direction

---

## Installation in Codex CLI (codex-skill-claude)

Prerequisites: Claude Code installed and authenticated (`claude --version`; run `claude` once interactively to log in), Codex CLI v0.145+ (for `codex plugin`), `python3` on PATH (used by the wrapper script to parse Claude's JSON output).

```bash
# 1. Add the marketplace
codex plugin marketplace add wywwzjj/cc-skill-codex

# 2. Install the plugin
codex plugin add codex-skill-claude@cc-skill-codex-marketplace

# Verify / manage
codex plugin list
codex plugin remove codex-skill-claude@cc-skill-codex-marketplace   # full id required
```

Then, in Codex: *"Use Claude to challenge the caching design in src/api/client.ts"*. The skill invokes Claude through its wrapper script (`claude-ask.sh`), which prints only the answer plus `SESSION_ID=`/`DETAILS=` trailer lines and persists the full JSON envelope and stderr for on-demand inspection. Claude runs with its own configured defaults — the skill imposes no tool or permission restrictions. See `plugins/codex-skill-claude/skills/claude/SKILL.md` for the full workflow.

> Heads-up: `claude -p` needs network access and writes session state to `~/.claude` — if your Codex session runs in a sandbox that blocks either, run Codex with network enabled for these commands.

---

## Installation in Claude Code (cc-skill-codex)

### Prerequisites

1. **Codex CLI** installed and authenticated:
   ```bash
   codex --version  # v0.145+ recommended (wrapper script uses `codex exec --json`; v0.142 works via the SKILL.md inline fallback)
   codex login
   ```

2. **Claude Code** installed and running

3. **python3** on PATH (used by the wrapper script to parse the Codex event stream)

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

### Upgrading from v3.2.x or earlier

v3.3.0 moved the plugin from the repository root into `plugins/cc-skill-codex/` (to make room for the second plugin). Marketplace-based installs migrate via the normal update path:

```bash
/plugin marketplace update cc-skill-codex-marketplace
/plugin update cc-skill-codex@cc-skill-codex-marketplace
```

If you loaded the plugin by pointing directly at the repository root (e.g. `--plugin-dir <repo>`), update the path to `<repo>/plugins/cc-skill-codex`.

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
codex --version  # v0.142+ recommended

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
1. Execute `codex exec` (via the wrapper script) with a steered prompt that explicitly asks it to challenge the design, surface hidden assumptions, and identify failure modes
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
1. Resume the prior session **by ID** (not `--last`): `bash "${CLAUDE_SKILL_DIR}/scripts/codex-ask.sh" resume <SESSION_ID> "Pressure-test the rollback path under partial failure"`
2. Resume with full context from the previous session — same target code, same prior reasoning
3. Build on what was already challenged rather than starting over

**Why ID-based resume matters**: `--last` resumes the most recent Codex session and races with any other Codex call (parallel reviews, the user invoking Codex directly, background tasks). The wrapper script prints a `SESSION_ID=<id>` line after every successful run — taken from the structured `thread.started` event, not scraped from stderr text — and that ID stays in Claude's context for follow-ups. If it ever scrolls out of context, it's still recoverable from the run's `DETAILS` directory (`events.jsonl`); `--last` is the final fallback.

**Why session continuation matters**: Codex sessions persist across Claude Code restarts. Multi-day reviews and investigations stay coherent — you can resume days later with full prior context.

### Step 8: Debug Investigation or Delegated Task

**Debug investigation**:
```
> Use Codex to investigate why my queue implementation deadlocks under high concurrency
```

Codex will trace the bug end-to-end and propose root cause + fix. You can then apply the fix yourself (with Claude) for tight control.

**Delegated task** (Codex actually writes the patch):
```
> Have Codex fix the deadlock in queue.py — apply the smallest safe patch
```

When the user clearly says "have Codex fix" or "let Codex patch", let Codex own the change. Whether Codex may write is governed by your configured sandbox in `~/.codex/config.toml` — the skill doesn't override it.

**Tradeoff**: investigation-then-apply gives Claude/you full control over the patch; a delegated fix is faster but Codex picks the implementation. Pick by how much you trust the local context vs. value the speed.

---

## Quick Tips

### Workflow Pattern
- **Adversarial / steerable review** is the flagship — challenge designs, pressure-test tradeoffs, find hidden risks
- **No restriction flags** — the skill passes no `-s`; Codex runs with the sandbox configured in your `~/.codex/config.toml`. Pass `-s` yourself only when you want a specific mode for a specific call
- **Pick by task fit, not by role** — both Codex and Claude can read and write code

### Triggering the Skill
- **Explicit**: "Use Codex to challenge...", "Use Codex to pressure-test...", "Use Codex to review..."
- **Keywords**: Mention "Codex" to explicitly trigger the skill
- **Steered**: For adversarial reviews, name the risk area — "challenge the retry design", "look for race conditions in the connection pool". Generic asks underperform focused ones.

### Model Usage
- **Model**: The skill does not pin a model — Codex CLI's current default is used (whichever model your installed Codex version ships with). To override, pass `-m <model>`.
- **Reasoning effort**: New sessions use `model_reasoning_effort=high` by default; resumed sessions inherit the original session's model + reasoning effort.

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
- `plugins/cc-skill-codex/skills/codex/SKILL.md` - Claude → Codex: skill definition, command patterns, and common failure guidance
- `plugins/codex-skill-claude/skills/claude/SKILL.md` - Codex → Claude: skill definition, command patterns, and common failure guidance

---

**License**: Apache 2.0
**Versions**: cc-skill-codex 3.3.1 · codex-skill-claude 1.0.1
**Codex CLI**: v0.145+ recommended (`codex plugin`, `codex exec --json`); base commands verified on v0.142.2 · **Claude Code**: verified on v2.1.206
**Runtime dependency**: `python3` on PATH (both wrapper scripts)
**Positioning**: peer coding agents in both directions — flagship use case is adversarial / steerable code review.
