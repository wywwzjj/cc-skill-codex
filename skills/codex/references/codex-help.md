# Codex CLI Help Reference

**Version**: 0.101.0

## Main Command: `codex --help`

```
Codex CLI

If no subcommand is specified, options will be forwarded to the interactive CLI.

Usage: codex [OPTIONS] [PROMPT]
       codex [OPTIONS] <COMMAND> [ARGS]

Commands:
  exec        Run Codex non-interactively [aliases: e]
  review      Run a code review non-interactively
  login       Manage login
  logout      Remove stored authentication credentials
  mcp         [experimental] Run Codex as an MCP server and manage MCP servers
  mcp-server  [experimental] Run the Codex MCP server (stdio transport)
  app-server  [experimental] Run the app server or related tooling
  app         Launch the Codex desktop app (downloads the macOS installer if missing)
  completion  Generate shell completion scripts
  sandbox     Run commands within a Codex-provided sandbox
  debug       Debugging tools
  apply       Apply the latest diff produced by Codex agent as a `git apply` to your local working
              tree [aliases: a]
  resume      Resume a previous interactive session (picker by default; use --last to continue the
              most recent)
  fork        Fork a previous interactive session (picker by default; use --last to fork the most
              recent)
  cloud       [EXPERIMENTAL] Browse tasks from Codex Cloud and apply changes locally
  features    Inspect feature flags
  help        Print this message or the help of the given subcommand(s)

Arguments:
  [PROMPT]
          Optional user prompt to start the session

Options:
  -c, --config <key=value>
          Override a configuration value that would otherwise be loaded from `~/.codex/config.toml`.
          Use a dotted path (`foo.bar.baz`) to override nested values. The `value` portion is parsed
          as TOML. If it fails to parse as TOML, the raw string is used as a literal.

          Examples: - `-c model="o3"` - `-c 'sandbox_permissions=["disk-full-read-access"]'` - `-c
          shell_environment_policy.inherit=all`

      --enable <FEATURE>
          Enable a feature (repeatable). Equivalent to `-c features.<name>=true`

      --disable <FEATURE>
          Disable a feature (repeatable). Equivalent to `-c features.<name>=false`

  -i, --image <FILE>...
          Optional image(s) to attach to the initial prompt

  -m, --model <MODEL>
          Model the agent should use

      --oss
          Convenience flag to select the local open source model provider. Equivalent to -c
          model_provider=oss; verifies a local LM Studio or Ollama server is running

      --local-provider <OSS_PROVIDER>
          Specify which local provider to use (lmstudio or ollama). If not specified with --oss,
          will use config default or show selection

  -p, --profile <CONFIG_PROFILE>
          Configuration profile from config.toml to specify default options

  -s, --sandbox <SANDBOX_MODE>
          Select the sandbox policy to use when executing model-generated shell commands

          [possible values: read-only, workspace-write, danger-full-access]

  -a, --ask-for-approval <APPROVAL_POLICY>
          Configure when the model requires human approval before executing a command

          Possible values:
          - untrusted:  Only run "trusted" commands (e.g. ls, cat, sed) without asking for user
            approval. Will escalate to the user if the model proposes a command that is not in the
            "trusted" set
          - on-failure: Run all commands without asking for user approval. Only asks for approval if
            a command fails to execute, in which case it will escalate to the user to ask for
            un-sandboxed execution

      --full-auto
          Convenience alias for low-friction sandboxed automatic execution (-a on-request, --sandbox
          workspace-write)

      --dangerously-bypass-approvals-and-sandbox
          Skip all confirmation prompts and execute commands without sandboxing. EXTREMELY
          DANGEROUS. Intended solely for running in environments that are externally sandboxed

  -C, --cd <DIR>
          Tell the agent to use the specified directory as its working root

      --add-dir <DIR>
          Additional directories that should be writable alongside the primary workspace

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

## Exec Command: `codex exec --help`

```
Run Codex non-interactively

Usage: codex exec [OPTIONS] [PROMPT] [COMMAND]

Commands:
  resume  Resume a previous session by id or pick the most recent with --last
  review  Run a code review against the current repository
  help    Print this message or the help of the given subcommand(s)

Arguments:
  [PROMPT]
          Initial instructions for the agent. If not provided as an argument (or if `-` is used),
          instructions are read from stdin

Options:
  -c, --config <key=value>
          Override a configuration value that would otherwise be loaded from `~/.codex/config.toml`.
          Use a dotted path (`foo.bar.baz`) to override nested values. The `value` portion is parsed
          as TOML. If it fails to parse as TOML, the raw string is used as a literal.

          Examples: - `-c model="o3"` - `-c 'sandbox_permissions=["disk-full-read-access"]'` - `-c
          shell_environment_policy.inherit=all`

      --enable <FEATURE>
          Enable a feature (repeatable). Equivalent to `-c features.<name>=true`

      --disable <FEATURE>
          Disable a feature (repeatable). Equivalent to `-c features.<name>=false`

  -i, --image <FILE>...
          Optional image(s) to attach to the initial prompt

  -m, --model <MODEL>
          Model the agent should use

      --oss
          Use open-source provider

      --local-provider <OSS_PROVIDER>
          Specify which local provider to use (lmstudio or ollama). If not specified with --oss,
          will use config default or show selection

  -s, --sandbox <SANDBOX_MODE>
          Select the sandbox policy to use when executing model-generated shell commands

          [possible values: read-only, workspace-write, danger-full-access]

  -p, --profile <CONFIG_PROFILE>
          Configuration profile from config.toml to specify default options

      --full-auto
          Convenience alias for low-friction sandboxed automatic execution (-a on-request, --sandbox
          workspace-write)

      --dangerously-bypass-approvals-and-sandbox
          Skip all confirmation prompts and execute commands without sandboxing. EXTREMELY
          DANGEROUS. Intended solely for running in environments that are externally sandboxed

  -C, --cd <DIR>
          Tell the agent to use the specified directory as its working root

      --skip-git-repo-check
          Allow running Codex outside a Git repository

      --add-dir <DIR>
          Additional directories that should be writable alongside the primary workspace

      --ephemeral
          Run without persisting session files to disk

      --output-schema <FILE>
          Path to a JSON Schema file describing the model's final response shape

      --color <COLOR>
          Specifies color settings for use in the output

          [default: auto]
          [possible values: always, never, auto]

      --json
          Print events to stdout as JSONL

  -o, --output-last-message <FILE>
          Specifies file where the last message from the agent should be written

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

## Exec Resume Command: `codex exec resume --help`

**Important**: Despite `[PROMPT]` appearing optional in syntax, a prompt is **required** in practice.
Omitting it will error: "No prompt provided."

```
Resume a previous session by id or pick the most recent with --last

Usage: codex exec resume [OPTIONS] [SESSION_ID] [PROMPT]

Arguments:
  [SESSION_ID]
          Conversation/session id (UUID) or thread name. UUIDs take precedence if it parses. If
          omitted, use --last to pick the most recent recorded session

  [PROMPT]
          Prompt to send after resuming the session. If `-` is used, read from stdin
          ⚠️ REQUIRED in practice - will error if omitted

Options:
  -c, --config <key=value>
          Override a configuration value that would otherwise be loaded from `~/.codex/config.toml`.
          Use a dotted path (`foo.bar.baz`) to override nested values. The `value` portion is parsed
          as TOML. If it fails to parse as TOML, the raw string is used as a literal.

          Examples: - `-c model="o3"` - `-c 'sandbox_permissions=["disk-full-read-access"]'` - `-c
          shell_environment_policy.inherit=all`

      --last
          Resume the most recent recorded session (newest) without specifying an id

      --all
          Show all sessions (disables cwd filtering)

      --enable <FEATURE>
          Enable a feature (repeatable). Equivalent to `-c features.<name>=true`

      --disable <FEATURE>
          Disable a feature (repeatable). Equivalent to `-c features.<name>=false`

  -i, --image <FILE>
          Optional image(s) to attach to the prompt sent after resuming

  -m, --model <MODEL>
          Model the agent should use

      --full-auto
          Convenience alias for low-friction sandboxed automatic execution (-a on-request, --sandbox
          workspace-write)

      --dangerously-bypass-approvals-and-sandbox
          Skip all confirmation prompts and execute commands without sandboxing. EXTREMELY
          DANGEROUS. Intended solely for running in environments that are externally sandboxed

      --skip-git-repo-check
          Allow running Codex outside a Git repository

      --ephemeral
          Run without persisting session files to disk

      --json
          Print events to stdout as JSONL

  -h, --help
          Print help (see a summary with '-h')
```

## Features Command: `codex features list`

```
undo                             stable             false
shell_tool                       stable             true
unified_exec                     stable             true
shell_snapshot                   stable             true
js_repl                          under development  false
web_search_request               deprecated         false
web_search_cached                deprecated         false
search_tool                      removed            false
runtime_metrics                  under development  false
sqlite                           under development  false
memory_tool                      under development  false
child_agents_md                  under development  false
apply_patch_freeform             under development  false
use_linux_sandbox_bwrap          under development  false
request_rule                     stable             true
experimental_windows_sandbox     removed            false
elevated_windows_sandbox         removed            false
remote_models                    stable             true
powershell_utf8                  under development  false
enable_request_compression       stable             true
collab                           experimental       true
apps                             experimental       false
skill_mcp_dependency_install     stable             true
skill_env_var_dependency_prompt  under development  false
steer                            stable             true
collaboration_modes              stable             true
personality                      stable             true
responses_websockets             under development  false
responses_websockets_v2          under development  false
```

## Code Review Command: `codex review`

Run code review non-interactively (useful for Claude to invoke).

⚠️ **Diff source flags (`--uncommitted`, `--base`, `--commit`) and `[PROMPT]` are mutually exclusive.**

```bash
# Diff source flags (no custom prompt allowed):
codex review --uncommitted              # Review staged, unstaged, and untracked changes
codex review --base main                # Review changes against main branch
codex review --commit HEAD~3            # Review changes introduced by a specific commit

# Custom prompt (uses default diff source):
codex review "Check for security issues"  # Custom review instructions

# Optional metadata (can combine with either pattern above):
codex review --title "feat: add auth"   # Optional commit title in review summary
```

```bash
# ❌ WRONG — causes error: "the argument '--uncommitted' cannot be used with '[PROMPT]'"
codex review --uncommitted "Check for security issues"
```
