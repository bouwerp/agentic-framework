# Multi-Platform Support

The Orchestrator-Worker-Validator framework supports 4 major AI coding platforms.

## Supported Platforms

| Platform | Installer Support | Verification | Status |
|----------|------------------|--------------|--------|
| **OpenCode** | ✅ Full | ✅ Full | Native |
| **Claude Code** | ✅ Full | ✅ Full | Recommended |
| **Gemini** | ✅ Full | ✅ Full | REST API |
| **Cursor** | ✅ Full | ✅ Full | Plugin-based |

## Quick Install

The installer auto-detects your platform:

```bash
./scripts/install.sh
```

Or specify platform explicitly:

```bash
# OpenCode
OPENCODE_CONFIG=~/.config/opencode ./scripts/install.sh

# Claude Code
claude plugin install figma@claude-plugins-official

# Gemini  
export GEMINI_CONFIG=~/.gemini && ./scripts/install.sh

# Cursor
export CURSOR_CONFIG=~/.cursor && ./scripts/install.sh
```

## Platform-Specific Details

### OpenCode (Native Support)

**Best for**: Custom workflows, full control

**Installation**:
```bash
./scripts/install.sh
```

**Installs**:
- Agents: `orchestrator.md`, `worker.md`, `validator.md`
- Tools: `gsr.ts`, `figma-rest.ts`, `figma-oauth.ts`
- Skills: `figma-interaction/`, `jira/`, `confluence/`
- Config: `opencode.json`

**Test**:
```bash
opencode run "Hello, I'm the Orchestrator"
```

---

### Claude Code (Recommended)

**Best for**: Figma-heavy workflows, official plugin support

**Installation**:
```bash
# Install official plugins
claude plugin install figma@claude-plugins-official
claude plugin install jira@claude-plugins-official
claude plugin install confluence@claude-plugins-official

# Or manual MCP setup
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp auth figma
```

**Installs**:
- Skills: O-W-V role definitions
- MCP: Figma, JIRA, Confluence servers
- Plugins: Official integrations

**Test**:
```bash
claude "Hello, I'm the Orchestrator"
```

---

### Gemini

**Best for**: Multi-turn conversations, free tier

**Installation**:
```bash
./scripts/install.sh
```

**Installs**:
- Skills: System instructions for roles
- Tools: Shell scripts (gsr.sh)
- Env: REST API setup

**Note**: Gemini has limited MCP support, uses REST API approach.

**Test**:
```bash
gemini --system="You are the Orchestrator" "Hello"
```

---

### Cursor

**Best for**: IDE integration, VS Code users

**Installation**:
```bash
./scripts/install.sh

# In Cursor chat:
/plugin-add figma
/plugin-add jira
```

**Installs**:
- Skills: Universal skills
- MCP: Manual configuration via GUI

**Test**:
```
Open Cursor agent chat
Type: "Hello, I'm the Orchestrator"
```

---

## Verification

After installation, verify your setup:

```bash
./scripts/verify.sh
```

This checks:
- ✓ Platform detected
- ✓ All components installed
- ✓ Environment variables set
- ✓ Configuration valid

## Environment Setup

All platforms require these environment variables:

```bash
# ~/.zshrc or ~/.bashrc
export FIGMA_PERSONAL_TOKEN='figd_your-token'
export ATLASSIAN_API_TOKEN='your-token'
export ATLASSIAN_EMAIL='your.email@example.com'
export ATLASSIAN_SITE='your-domain.atlassian.net'
```

Get tokens:
- **Figma**: https://www.figma.com/developers/api#access-tokens
- **Atlassian**: https://id.atlassian.com/manage-profile/security/api-tokens

## Platform Comparison

| Feature | OpenCode | Claude Code | Gemini | Cursor |
|---------|----------|-------------|---------|--------|
| **Agent Config** | Markdown | Skills | System instructions | Skills |
| **Tool System** | TypeScript | MCP plugins | Shell scripts | MCP |
| **MCP Support** | Full | Full (best) | Limited | Full |
| **Figma** | REST + OAuth | Official MCP | REST API | MCP plugin |
| **JIRA** | REST + ADF | MCP plugin | REST API | MCP plugin |
| **Confluence** | REST + ADF | MCP plugin | REST API | MCP plugin |
| **Models** | Any (OpenRouter) | Claude only | Gemini only | Any |
| **Best For** | Custom | Figma-heavy | Free tier | IDE users |

## Troubleshooting

### Installation fails
```bash
# Check platform detection
./scripts/verify.sh

# Manual install for your platform
# See platform-specific sections above
```

### Tools not available
```bash
# Verify installation
./scripts/verify.sh

# Re-run installer
./scripts/install.sh
```

### Platform not detected
```bash
# Set config directory explicitly
export OPENCODE_CONFIG=~/.config/opencode
export CLAUDE_CONFIG=~/.claude
export GEMINI_CONFIG=~/.gemini
export CURSOR_CONFIG=~/.cursor

./scripts/install.sh
```

## Getting Help

- **Documentation**: See README.md and INSTALL.md
- **Platform guides**: See `platforms/` directory
- **Issues**: https://github.com/bouwerp/agentic-framework/issues
