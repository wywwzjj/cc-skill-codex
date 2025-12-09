# cc-skill-codex

A Claude Code **plugin** that provides a skill for seamless OpenAI Codex CLI integration with GPT-5.1 high-reasoning capabilities.

**Philosophy**: Codex = Brain (thinking), Claude = Hands (implementation)

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
        ├── SKILL.md            # Main skill definition (loaded by Claude Code)
        └── references/         # Reference documentation (for users)
            ├── command-patterns.md      # Design → Implementation workflows
            ├── session-workflows.md     # Session continuation patterns
            ├── troubleshooting.md       # Error solutions and debugging
            ├── codex-config.md          # Complete configuration reference
            ├── codex-help.md            # Codex CLI v0.58 help reference
            └── advanced-patterns.md     # Advanced options
```

**How it works**:
1. You add the **marketplace** (`cc-skill-codex-marketplace`) from GitHub
2. You install the **plugin** (`cc-skill-codex`) from the marketplace
3. The plugin provides the **skill** (`codex`)
4. Claude Code loads `skills/codex/SKILL.md` when the skill is invoked
5. All other files are documentation for users

---

## Installation in Claude Code

### Prerequisites

1. **Codex CLI** installed and authenticated:
   ```bash
   codex --version  # v0.58+
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

The skill will invoke Codex CLI with GPT-5.1 high-reasoning capabilities.

---

## Step-by-Step Tutorial

### Step 1: Install Prerequisites

```bash
# Check if Codex CLI is installed
codex --version  # Requires v0.58+

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

### Step 5: Use Codex for Design (Brain)

**Design request** (Codex thinks, Claude implements):
```
> Use Codex to design a REST API for a blog system
```

Codex will:
1. Execute: `codex exec -m gpt-5.1 -s read-only -c model_reasoning_effort=high -c hide_agent_reasoning=true "Design a REST API..."`
2. Provide high-level architecture, endpoint design, data models
3. Session auto-saved for continuation

**Then implement with Claude**:
```
> Implement the user authentication endpoint based on Codex's design
```

Claude will implement the code using Codex's design.

### Step 6: Use Codex for Code Review

**Review request**:
```
> Use Codex to review this authentication code for security issues
```

Codex will:
1. Analyze with high reasoning (read-only mode)
2. Identify vulnerabilities and best practice violations
3. Provide improvement recommendations

**Then fix with Claude**:
```
> Fix the security issues in auth.py:45-67 as Codex suggested
```

### Step 7: Continue a Session

**Follow-up request**:
```
> Continue with that API - add error handling
```

Codex will:
1. Execute: `codex exec -m gpt-5.1 -c hide_agent_reasoning=true resume --last "Add comprehensive error handling to the API"`
2. Resume with full context from previous session
3. Build on previous design decisions

**Why this matters**: Codex sessions persist across Claude Code restarts - you can resume days later with full context.

### Step 8: Debug Analysis

**Debug request**:
```
> Use Codex to analyze why my queue implementation deadlocks under high concurrency
```

Codex will:
1. Perform deep reasoning analysis
2. Identify root cause and race conditions
3. Suggest debugging approach and fixes

**Then implement fix with Claude**:
```
> Apply the fix Codex suggested at lines 23-45
```

---

## Quick Tips

### Workflow Pattern
- **Codex = Brain**: Design, architecture, code review, debug analysis (read-only)
- **Claude = Hands**: Implementation, refactoring, file modifications

### Triggering the Skill
- **Explicit**: "Use Codex to design...", "Use Codex to review..."
- **Keywords**: Mention "Codex" to explicitly trigger the skill
- **Best practice**: Be explicit about what you want Codex to do

### Model Usage
- **gpt-5.1** (default): General reasoning, architecture design, code review
- **gpt-5.1-codex**: Code editing tasks (rare - usually let Claude implement)
- **Default reasoning**: High reasoning effort for maximum quality

### Session Continuation
- **Keywords**: "continue", "resume", "add to that", "keep going"
- **Persistence**: Sessions survive Claude Code restarts
- **Long-term context**: Resume projects days or weeks later with full history

### Common Use Cases
| Task | Use Codex? | Example |
|------|-----------|---------|
| Design architecture | ✅ Yes | "Use Codex to design a caching layer" |
| Review security | ✅ Yes | "Use Codex to review for vulnerabilities" |
| Debug analysis | ✅ Yes | "Use Codex to analyze this deadlock" |
| Implement code | ❌ No | Let Claude implement based on Codex's design |
| Refactor code | ❌ No | Let Claude refactor based on Codex's review |

---

## Documentation

For detailed information, see:
- `skills/codex/SKILL.md` - Main skill documentation
- `skills/codex/references/command-patterns.md` - Design → Implementation workflows
- `skills/codex/references/session-workflows.md` - Session continuation examples
- `skills/codex/references/troubleshooting.md` - Error solutions and debugging
- `skills/codex/references/codex-config.md` - Configuration reference

---

**License**: Apache 2.0
**Version**: 2.0.0
**Codex CLI**: v0.58+
**Philosophy**: Codex = Brain (thinking), Claude = Hands (implementation)
