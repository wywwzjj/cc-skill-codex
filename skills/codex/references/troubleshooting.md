# Troubleshooting Guide

---

## Common Errors

### Error 1: No Prompt Provided

**Error Message**:
```
Error: No prompt provided. Either specify one as an argument or pipe the prompt into stdin.
```

**Cause**: Using `codex exec resume` without providing a prompt.

**Solutions**:
```bash
# ✅ Solution 1: Direct prompt argument
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume --last "your prompt here"

# ❌ WRONG - will always fail (no prompt)
codex exec resume --last
```

**Why**: The Codex CLI requires a prompt to resume sessions. The `[PROMPT]` parameter appears optional in syntax but is required in practice.

---

### Error 1.5: Multi-line Prompt Parsing Error

**Error**: `error: the argument '--last' cannot be used with '[SESSION_ID]'`

**Cause**: Either unescaped newlines in Bash arguments, OR adding `-` after `--last` (the `-` gets parsed as SESSION_ID).

**Solution**:
```bash
# ✅ Use heredoc (NO trailing -)
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume --last <<'EOF'
Multi-line prompt here
EOF

# ❌ WRONG - Don't add - after --last
codex exec -m gpt-5.2 resume --last -
```

---

### Error 1.6: Model Mismatch Warning on Resume

**Warning**: `This session was recorded with model 'gpt-5.2' but is resuming with 'gpt-5.2-codex'`

**Cause**: Not specifying model when resuming, causing Codex to use default model instead of original session's model.

**Solution**:
```bash
# ✅ Always specify model matching original session (-m before resume)
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume --last "continue"

# Or with explicit session ID
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume "$SESSION_ID" "continue"
```

---

### Error 1.7: Session Confusion with Multiple Claude Code Instances

**Problem**: When running multiple Claude Code instances, `--last` may resume the wrong session because it points to the globally most recent session.

**Cause**: `--last` is global across all Codex sessions, not scoped to individual Claude Code instances.

**Solutions**:

**Option 1**: Track session ID explicitly
```bash
# Capture session ID from first call
SESSION_ID=$(codex exec -m gpt-5.2 -c hide_agent_reasoning=true "prompt" 2>&1 | grep -o 'session id: [a-f0-9-]*' | cut -d' ' -f3)

# Resume with specific session ID and model (-m before resume)
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume "$SESSION_ID" <<'EOF'
Continue prompt
EOF
```

**Option 2**: Use only one Claude Code instance with Codex at a time

**Option 3**: Use session naming/tagging (if available in future Codex CLI versions)

---

### Error 2: "stdout is not a terminal"

**Error Message**:
```
Error: stdout is not a terminal
```

**Cause**: Using `codex` (interactive mode) instead of `codex exec` (non-interactive mode).

**Solution**:
```bash
# ❌ WRONG - interactive mode fails in Claude Code
codex -m gpt-5.2 "prompt"
codex resume --last "prompt"

# ✅ CORRECT - use codex exec
codex exec -m gpt-5.2 -c hide_agent_reasoning=true "prompt"
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume --last "prompt"
```

**Why**: Claude Code's bash environment is non-TTY (non-interactive). Only `codex exec` works in this environment.

---

### Error 3: Command Not Found

**Error Message**:
```
bash: codex: command not found
```

**Cause**: Codex CLI not installed or not in PATH.

**Solutions**:

1. **Check if installed**:
```bash
which codex
codex --version
```

2. **Install Codex CLI** (if not installed):
```bash
# Follow official installation instructions
# https://developers.openai.com/codex/cli/installation
```

3. **Add to PATH** (if installed but not in PATH):
```bash
# Check installation location
find ~ -name "codex" -type f 2>/dev/null

# Add to PATH in your shell config (~/.zshrc or ~/.bashrc)
export PATH="$PATH:/path/to/codex/bin"
```

---

### Error 4: Authentication Required

**Error Message**:
```
Error: Not authenticated with Codex
```

**Cause**: Not logged in to Codex CLI.

**Solution**:
```bash
# Run login command
codex login

# Follow authentication prompts
# After successful login, try your command again
```

---

### Error 5: Invalid Model Specified

**Error Message**:
```
Error: Invalid model specified
```

**Cause**: Using an unsupported or non-existent model name.

**Solution**:
```bash
# ✅ Use supported models
codex exec -m gpt-5.2 -c hide_agent_reasoning=true "prompt"           # General reasoning
codex exec -m gpt-5.2-codex -c hide_agent_reasoning=true "prompt"     # Code editing

# ❌ Common mistakes
codex exec -m gpt-5 "prompt"             # Wrong version
codex exec -m codex "prompt"             # Wrong name
```

**Valid models**:
- `gpt-5.2` - General reasoning, architecture design
- `gpt-5.2-codex` - Code editing tasks
- `gpt-5.1-codex-max` - Flagship Codex model

---

### Error 6: Permission Denied (Sandbox)

**Error Message**:
```
Error: Permission denied: cannot write to file
```

**Cause**: Trying to modify files while in `read-only` sandbox mode.

**Solution**:

1. **Check if you really need to write** - Remember: Codex = Brain (thinking), Claude = Hands (implementation)

2. **If Codex must write**, use `workspace-write`:
```bash
codex exec -s workspace-write -c hide_agent_reasoning=true "prompt"
```

3. **Or use `--full-auto`** (workspace-write + on-request approval):
```bash
codex exec --full-auto -c hide_agent_reasoning=true "prompt"
```

**Best practice**: Default to `read-only` and let Claude handle file modifications.

---

### Error 7: Session Not Found

**Error Message**:
```
Error: No previous sessions found
```

**Cause**: Trying to resume when no Codex sessions exist yet.

**Solution**:

1. **Start a new session first**:
```bash
codex exec -m gpt-5.2 -c hide_agent_reasoning=true "Your initial prompt"
```

2. **Then resume in subsequent requests**:
```bash
codex exec -m gpt-5.2 -c hide_agent_reasoning=true resume --last "Continue with..."
```

**Note**: Sessions only exist after you've run at least one `codex exec` command.

---

### Error 8: Web Search Not Available

**Error Message**:
```
Error: Unknown option: --search
```

**Cause**: Using `--search` flag with `codex exec` (not supported).

**Solution**:
```bash
# ❌ WRONG - --search only works with interactive `codex`
codex exec --search "prompt"

# ✅ CORRECT - use --enable web_search_request
codex exec --enable web_search_request -c hide_agent_reasoning=true "prompt"

# ✅ Or enable in config.toml
[features]
web_search_request = true
```

---

### Error 9: Configuration File Issues

**Error Message**:
```
Error: Failed to parse config file
```

**Cause**: Invalid TOML syntax in `~/.codex/config.toml`.

**Solutions**:

1. **Check TOML syntax**:
```bash
# Validate config file
cat ~/.codex/config.toml
```

2. **Common TOML mistakes**:
```toml
# ❌ WRONG - missing quotes
model = gpt-5.2

# ✅ CORRECT - strings need quotes
model = "gpt-5.2"

# ❌ WRONG - incorrect array syntax
[features]
web_search_request = [true]

# ✅ CORRECT - boolean not array
[features]
web_search_request = true
```

3. **Reset to default config**:
```bash
# Backup current config
mv ~/.codex/config.toml ~/.codex/config.toml.backup

# Create new minimal config
cat > ~/.codex/config.toml << 'EOF'
model = "gpt-5.2"
sandbox_mode = "read-only"

[features]
web_search_request = true
EOF
```

---

### Error 10: MCP Server Connection Failed

**Error Message**:
```
Error: Failed to connect to MCP server
```

**Cause**: MCP server configuration issue.

**Solutions**:

1. **Check MCP server config**:
```toml
# For HTTP servers
[mcp_servers.deepwiki]
url = "https://mcp.deepwiki.com/mcp"

# For stdio servers
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
```

2. **Test server connectivity**:
```bash
# For HTTP servers
curl -I https://mcp.deepwiki.com/mcp

# For stdio servers (check if command exists)
which npx
npx -y @upstash/context7-mcp --version
```

3. **Disable problematic server temporarily**:
```toml
[mcp_servers.problematic_server]
enabled = false
```

---

## Troubleshooting Workflows

### Issue: Skill Not Triggering

**Symptoms**: Claude doesn't invoke the Codex skill when expected.

**Diagnosis**:
1. Check if user explicitly mentioned "Codex"
2. Verify skill is installed correctly
3. Check YAML frontmatter is valid

**Solutions**:
1. **Be explicit**: "Use Codex to design..."
2. **Check installation**:
```bash
ls -la ~/.claude/plugins/marketplaces/cc-skill-codex-marketplace/skills/codex/
cat ~/.claude/plugins/marketplaces/cc-skill-codex-marketplace/skills/codex/SKILL.md | head -5
```

---

### Issue: Session Not Resuming Correctly

**Symptoms**: Resume works but context seems lost.

**Diagnosis**:
1. Multiple sessions might be mixed
2. User might have requested "fresh start"
3. Wrong session being resumed

**Solutions**:

1. **List recent sessions**:
```bash
codex list
```

2. **Resume specific session by ID**:
```bash
codex exec -c hide_agent_reasoning=true resume <session-id> "prompt"
```

3. **Verify session exists**:
```bash
# Check session directory
ls -la ~/.codex/sessions/
```

---

### Issue: Performance Problems

**Symptoms**: Codex responses are slow or incomplete.

**Solutions**:

1. **Lower reasoning effort for simple tasks**:
```bash
codex exec -c model_reasoning_effort=medium -c hide_agent_reasoning=true "simple task"
codex exec -c model_reasoning_effort=low -c hide_agent_reasoning=true "quick check"
```

2. **Reduce verbosity**:
```bash
codex exec -c model_verbosity=low -c hide_agent_reasoning=true "concise task"
```

3. **Check network connectivity**:
```bash
ping api.openai.com
```

---

### Issue: Unexpected File Modifications

**Symptoms**: Codex modified files when it shouldn't have.

**Cause**: Using `workspace-write` or `danger-full-access` when `read-only` would be appropriate.

**Prevention**:

1. **Default to read-only**:
```toml
# In ~/.codex/config.toml
sandbox_mode = "read-only"
```

2. **Only use workspace-write when explicitly needed**:
```bash
# Only when Codex must actually modify files
codex exec -s workspace-write -c hide_agent_reasoning=true "specific task requiring writes"
```

3. **Remember the pattern**: Codex = Brain (read-only), Claude = Hands (workspace-write)

---

## Getting Help

### Built-in Help

```bash
# General help
codex --help
codex exec --help

# Specific command help
codex exec resume --help

# Version info
codex --version
```

### Official Resources

- **CLI Reference**: https://developers.openai.com/codex/cli/reference
- **Configuration**: https://developers.openai.com/codex/local-config
- **Installation**: https://developers.openai.com/codex/cli/installation

### Skill Resources

- **Main skill doc**: `../SKILL.md`
- **Usage patterns**: `command-patterns.md`
- **Configuration**: `codex-config.md`
- **Session workflows**: `session-workflows.md`
- **Advanced options**: `advanced-patterns.md`

---

## Debug Mode

Enable verbose output for debugging:

```bash
# Run with verbose logging (if supported)
codex exec -v "prompt"

# Check config being used
codex config show

# Test authentication
codex auth status
```

---

## Still Stuck?

If you've tried the above and still have issues:

1. **Check Codex version**: `codex --version` (ensure you have v0.77+)
2. **Review logs**: Check `~/.codex/logs/` if available
3. **Minimal reproduction**: Try simplest possible command:
   ```bash
   codex exec -m gpt-5.2 -c hide_agent_reasoning=true "Hello"
   ```
4. **Configuration reset**: Temporarily rename config to test with defaults:
   ```bash
   mv ~/.codex/config.toml ~/.codex/config.toml.backup
   codex exec -m gpt-5.2 -c hide_agent_reasoning=true "test"
   ```
