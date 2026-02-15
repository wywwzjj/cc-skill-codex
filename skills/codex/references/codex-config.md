# Codex Configuration Reference

**Config file location**: `~/.codex/config.toml`
**Codex CLI Version**: v0.101.0+

---

## Recommended Configuration for Claude Code

**Use Codex as thinking assistant (Brain), Claude for implementation (Hands)**

```toml
# Primary settings
model = "gpt-5.3-codex"  # Agentic coding model (recommended)
model_reasoning_effort = "high"  # Maximum reasoning capability
sandbox_mode = "read-only"  # Default: analyze but don't modify files

# Optional: MCP server integration
[mcp_servers.deepwiki]
url = "https://mcp.deepwiki.com/mcp"

# Optional: Trust your project directories
[projects."/path/to/your/project"]
trust_level = "trusted"
```

**Why these settings?**
- `gpt-5.3-codex`: Best for agentic coding tasks (design, review, debug)
- `read-only`: Codex analyzes, Claude implements
- `high` reasoning: Maximize thinking quality

---

## Core Configuration Options

### Model Settings

| Key | Type / Values | Default | Notes |
|-----|---------------|---------|-------|
| `model` | string | varies | Model to use (e.g., `gpt-5.3`, `gpt-5.3-codex`) |
| `model_provider` | string | `openai` | Provider id from model_providers |
| `model_context_window` | number | - | Context window tokens |
| `model_max_output_tokens` | number | - | Max output tokens |
| `model_reasoning_effort` | `minimal` \| `low` \| `medium` \| `high` \| `xhigh` | varies | Responses API reasoning effort |
| `model_verbosity` | `low` \| `medium` \| `high` | varies | GPT-5 text verbosity (base models only, not `-codex` models) |
| `model_reasoning_summary` | `auto` \| `concise` \| `detailed` | `auto` | Reasoning summaries format |

### Execution Control

| Key | Type / Values | Default | Notes |
|-----|---------------|---------|-------|
| `approval_policy` | `untrusted` \| `on-failure` | - | When to prompt for approval |
| `sandbox_mode` | `read-only` \| `workspace-write` \| `danger-full-access` | `read-only` | OS sandbox policy |

**Approval policies**:
- `untrusted`: Only run trusted commands (ls, cat, sed) without asking
- `on-failure`: Run all commands, only ask if one fails

### Sandbox Configuration

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `sandbox_workspace_write.writable_roots` | array | `[]` | Extra writable directories |
| `sandbox_workspace_write.network_access` | boolean | `false` | Allow network access |
| `sandbox_workspace_write.exclude_tmpdir_env_var` | boolean | `false` | Exclude $TMPDIR from writable roots |
| `sandbox_workspace_write.exclude_slash_tmp` | boolean | `false` | Exclude /tmp from writable roots |

**Example**:
```toml
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
writable_roots = ["/Users/YOU/.pyenv/shims"]
network_access = false
```

---

## Features Configuration

**Location**: `[features]` table

Features can be enabled/disabled in config or via CLI flags:
- Config: `[features]` section in `config.toml`
- CLI: `codex exec --enable feature_name` or `--disable feature_name`

### Available Features

| Feature | Default | Stability | Description |
|---------|---------|-----------|-------------|
| `shell_tool` | true | Stable | Shell command execution |
| `unified_exec` | true | Stable | PTY-backed unified execution tool |
| `shell_snapshot` | true | Stable | Shell snapshot support |
| `request_rule` | true | Stable | Request rule processing |
| `remote_models` | true | Stable | Remote model support |
| `enable_request_compression` | true | Stable | Request compression |
| `skill_mcp_dependency_install` | true | Stable | Auto-install MCP skill dependencies |
| `steer` | true | Stable | Steering capabilities |
| `collaboration_modes` | true | Stable | Collaboration mode support |
| `personality` | true | Stable | Personality configuration (default: friendly) |
| `collab` | true | Experimental | Collaboration features |
| `undo` | false | Stable | Undo capability |
| `web_search_request` | false | **Deprecated** | Web search (deprecated) |
| `web_search_cached` | false | **Deprecated** | Cached web search (deprecated) |
| `apps` | false | Experimental | Apps support |
| `js_repl` | false | Under Development | JavaScript REPL |
| `sqlite` | false | Under Development | SQLite support |
| `memory_tool` | false | Under Development | Memory tool |
| `apply_patch_freeform` | false | Under Development | Freeform patch application |

**Note**: Most useful features are enabled by default. `web_search_request` is now deprecated. Use `--disable <feature>` only when needed.

**Example**:
```toml
[features]
web_search_request = true
shell_snapshot = true
```

**CLI usage**:
```bash
codex exec --enable web_search_request -c hide_agent_reasoning=true "Research latest patterns"
```

---

## Shell Environment Policy

Control which environment variables are passed to executed commands.

| Key | Type | Description |
|-----|------|-------------|
| `shell_environment_policy.inherit` | `all` \| `core` \| `none` | Which env vars to inherit |
| `shell_environment_policy.exclude` | array of strings | Patterns to exclude (e.g., `["AWS_*"]`) |
| `shell_environment_policy.include_only` | array of strings | Only include these vars |
| `shell_environment_policy.set` | map<string,string> | Set custom environment variables |

**Example**:
```toml
[shell_environment_policy]
inherit = "core"
exclude = ["AWS_*", "AZURE_*"]
include_only = ["PATH", "HOME"]
set = { MY_VAR = "value" }
```

---

## MCP Servers

Configure Model Context Protocol servers for extended capabilities.

### Stdio Servers

| Key | Type | Description |
|-----|------|-------------|
| `mcp_servers.<id>.command` | string | Launcher command |
| `mcp_servers.<id>.args` | array | Command arguments |
| `mcp_servers.<id>.env` | map<string,string> | Environment variables |
| `mcp_servers.<id>.enabled` | boolean | Enable/disable server (default: true) |
| `mcp_servers.<id>.startup_timeout_sec` | number | Startup timeout (default: 10) |
| `mcp_servers.<id>.tool_timeout_sec` | number | Per-tool timeout (default: 60) |
| `mcp_servers.<id>.enabled_tools` | array | Restrict to listed tool names |
| `mcp_servers.<id>.disabled_tools` | array | Disable specific tools |

**Example**:
```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
```

### HTTP Servers

| Key | Type | Description |
|-----|------|-------------|
| `mcp_servers.<id>.url` | string | Server URL |
| `mcp_servers.<id>.bearer_token_env_var` | string | Env var containing bearer token |

**Example**:
```toml
[mcp_servers.deepwiki]
url = "https://mcp.deepwiki.com/mcp"
```

---

## Model Providers

Configure custom model providers beyond OpenAI.

| Key | Type | Description |
|-----|------|-------------|
| `model_providers.<id>.name` | string | Display name |
| `model_providers.<id>.base_url` | string | API base URL |
| `model_providers.<id>.env_key` | string | Env var for API key |
| `model_providers.<id>.wire_api` | `chat` \| `responses` | Protocol (default: chat) |
| `model_providers.<id>.query_params` | map<string,string> | Extra query params |
| `model_providers.<id>.http_headers` | map<string,string> | Static headers |
| `model_providers.<id>.env_http_headers` | map<string,string> | Headers from env vars |
| `model_providers.<id>.request_max_retries` | number | HTTP retry count (default: 4) |
| `model_providers.<id>.stream_max_retries` | number | SSE retry count (default: 5) |
| `model_providers.<id>.stream_idle_timeout_ms` | number | SSE idle timeout (default: 300000) |

**Example**:
```toml
[model_providers.ollama]
name = "Ollama"
base_url = "http://localhost:11434/v1"

[model_providers.mistral]
name = "Mistral"
base_url = "https://api.mistral.ai/v1"
env_key = "MISTRAL_API_KEY"
```

---

## Profiles

Create reusable configuration profiles for different use cases.

```toml
[profiles.design]
model = "gpt-5.3-codex"
sandbox_mode = "read-only"
model_reasoning_effort = "high"

[profiles.implement]
model = "gpt-5.3-codex"
sandbox_mode = "workspace-write"
approval_policy = "on-request"
```

**Usage**:
```bash
codex exec --profile design -c hide_agent_reasoning=true "Design REST API"
```

**Priority**: Profile settings override root-level settings but are overridden by explicit CLI flags.

---

## History & Session Management

| Key | Type / Values | Default | Description |
|-----|---------------|---------|-------------|
| `history.persistence` | `save-all` \| `none` | `save-all` | History file persistence |
| `history.max_bytes` | number | - | Currently ignored (not enforced) |

---

## IDE Integration

| Key | Type / Values | Default | Description |
|-----|---------------|---------|-------------|
| `file_opener` | `vscode` \| `vscode-insiders` \| `windsurf` \| `cursor` \| `none` | `vscode` | URI scheme for clickable citations |

---

## Project Trust Levels

Mark specific project directories as trusted to bypass certain security checks.

```toml
[projects."/path/to/trusted/project"]
trust_level = "trusted"
```

**Use case**: Projects you fully trust and want fewer approval prompts.

---

## Notifications & Telemetry

### Notifications

| Key | Type | Description |
|-----|------|-------------|
| `notify` | array | External program for notifications |
| `tui.notifications` | boolean \| array | Enable desktop notifications (default: false) |

**Example**:
```toml
notify = ["python3", "/path/to/notify.py"]
```

### OpenTelemetry (OTEL)

| Key | Type | Description |
|-----|------|-------------|
| `otel.environment` | string | Environment name (e.g., "staging") |
| `otel.exporter` | string | Exporter type (e.g., "otlp-http") |
| `otel.log_user_prompt` | boolean | Log user prompts (default: false) |

---

## Deprecated Configuration Items

⚠️ **These are deprecated** - migrate to `[features]` table:

| Old Key | New Key | Notes |
|---------|---------|-------|
| `experimental_use_exec_command_tool` | `[features].unified_exec` | Unified execution tool |
| `experimental_use_rmcp_client` | `[features].rmcp_client` | RMCP client support |
| `tools.web_search` | `[features].web_search_request` | Web search capability |
| `tools.view_image` | `[features].view_image_tool` | Image viewing tool |

**Migration example**:
```toml
# Old (deprecated)
tools.web_search = true

# New (correct)
[features]
web_search_request = true
```

---

## Other Advanced Settings

| Key | Type / Values | Description |
|-----|---------------|-------------|
| `project_doc_max_bytes` | number | Max bytes to read from AGENTS.md |
| `profile` | string | Active profile name |
| `hide_agent_reasoning` | boolean | **IMPORTANT for Claude Code**: Hide model reasoning events to reduce context consumption |
| `show_raw_agent_reasoning` | boolean | Show raw reasoning (when available) |
| `model_supports_reasoning_summaries` | boolean | Force-enable reasoning summaries |
| `model_reasoning_summary_format` | `none` \| `experimental` | Force reasoning summary format |
| `chatgpt_base_url` | string | Base URL for ChatGPT auth flow |
| `experimental_instructions_file` | string (path) | Replace built-in instructions (experimental) |
| `experimental_use_exec_command_tool` | boolean | **Deprecated** - use `[features].unified_exec` |
| `forced_login_method` | `chatgpt` \| `api` | Restrict authentication method |
| `forced_chatgpt_workspace_id` | string (uuid) | Restrict to specific ChatGPT workspace |

---

## Configuration Priority

From highest to lowest:

1. **Explicit CLI flags**: `--model gpt-5.3-codex`, `--enable feature`
2. **Profile settings**: `--profile design`
3. **Root-level config**: Settings in `config.toml`
4. **Built-in defaults**: CLI's default values

**Example**:
```bash
# Profile has model="gpt-5.3"
# But CLI flag overrides it
codex exec --profile myprofile --model gpt-5.3-codex -c hide_agent_reasoning=true "prompt"
# Uses gpt-5.3-codex (CLI flag wins)
```

---

## Complete Example Configuration

```toml
# Recommended for Claude Code: Codex as thinking assistant
model = "gpt-5.3-codex"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
approval_policy = "on-failure"

# IMPORTANT: Hide reasoning output to reduce Claude's context consumption
hide_agent_reasoning = true

# Shell environment
[shell_environment_policy]
inherit = "core"
exclude = ["AWS_*"]

# Sandbox configuration (if using workspace-write)
[sandbox_workspace_write]
network_access = false
writable_roots = ["/Users/YOU/.pyenv/shims"]

# MCP servers
[mcp_servers.deepwiki]
url = "https://mcp.deepwiki.com/mcp"

# Profiles for different use cases
[profiles.design]
model = "gpt-5.3-codex"
sandbox_mode = "read-only"
model_reasoning_effort = "high"

[profiles.review]
model = "gpt-5.3-codex"
sandbox_mode = "read-only"
model_reasoning_effort = "high"

# Trust your projects
[projects."/Users/YOU/my-project"]
trust_level = "trusted"

# History
[history]
persistence = "save-all"

# IDE integration
file_opener = "vscode"

# Notifications (optional)
notify = ["python3", "/path/to/notify.py"]
```

---

## Quick Tips

### For Claude Code Integration
- Use `gpt-5.3-codex` for agentic coding tasks (recommended)
- Default to `read-only` sandbox - let Claude do the coding
- Use profiles to switch between design/review/implementation modes

### For Performance
- Lower `model_reasoning_effort` for simple tasks
- Use `sandbox_mode = "read-only"` for faster approval-free execution

### For Security
- Start with `read-only` or `workspace-write`, avoid `danger-full-access`
- Use `approval_policy = "on-request"` for sensitive operations
- Set `trust_level = "trusted"` only for projects you fully control
