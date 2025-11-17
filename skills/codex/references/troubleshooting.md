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
codex exec resume --last "your prompt here"

# ✅ Solution 2: Pipe via stdin
echo "your prompt" | codex exec resume --last -

# ❌ WRONG - will always fail
codex exec resume --last
```

**Why**: The Codex CLI requires a prompt to resume sessions. The `[PROMPT]` parameter appears optional in syntax but is required in practice.

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
codex -m gpt-5.1 "prompt"
codex resume --last "prompt"

# ✅ CORRECT - use codex exec
codex exec -m gpt-5.1 "prompt"
codex exec resume --last "prompt"
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
codex exec -m gpt-5.1 "prompt"           # General reasoning
codex exec -m gpt-5.1-codex "prompt"     # Code editing

# ❌ Common mistakes
codex exec -m gpt-5 "prompt"             # Wrong version
codex exec -m codex "prompt"             # Wrong name
```

**Valid models**:
- `gpt-5.1` - General reasoning, architecture design
- `gpt-5.1-codex` - Code editing tasks

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
codex exec -s workspace-write "prompt"
```

3. **Or use `--full-auto`** (workspace-write + on-request approval):
```bash
codex exec --full-auto "prompt"
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
codex exec -m gpt-5.1 "Your initial prompt"
```

2. **Then resume in subsequent requests**:
```bash
codex exec resume --last "Continue with..."
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
codex exec --enable web_search_request "prompt"

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
model = gpt-5.1

# ✅ CORRECT - strings need quotes
model = "gpt-5.1"

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
model = "gpt-5.1"
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
codex exec resume <session-id> "prompt"
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
codex exec -c model_reasoning_effort=medium "simple task"
codex exec -c model_reasoning_effort=low "quick check"
```

2. **Reduce verbosity**:
```bash
codex exec -c model_verbosity=low "concise task"
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
codex exec -s workspace-write "specific task requiring writes"
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

1. **Check Codex version**: `codex --version` (ensure you have v0.58+)
2. **Review logs**: Check `~/.codex/logs/` if available
3. **Minimal reproduction**: Try simplest possible command:
   ```bash
   codex exec -m gpt-5.1 "Hello"
   ```
4. **Configuration reset**: Temporarily rename config to test with defaults:
   ```bash
   mv ~/.codex/config.toml ~/.codex/config.toml.backup
   codex exec -m gpt-5.1 "test"
   ```
