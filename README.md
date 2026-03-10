# Orchestrator-Worker-Validator Framework

An agentic framework for opencode that implements a three-tier collaboration pattern with:
- **GSR (Global Search & Replace)** for large-scale refactors
- **Figma integration** for design-to-code workflows
- **Dynamic model tiering** for optimal performance

## Quick Start

### Option 1: Automatic Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/bouwerp/agentic-framework.git
cd agentic-framework

# Run the installer
./scripts/install.sh
```

The installer will:
- Copy agents, tools, and skills to your opencode config
- Optionally merge the configuration
- Provide setup instructions for API tokens

### Option 2: Manual Installation

```bash
# Copy agents
cp -r .opencode/agents ~/.config/opencode/

# Copy tools
cp -r .opencode/tools ~/.config/opencode/

# Copy skills
cp -r .opencode/skills ~/.config/opencode/

# Copy configuration
cp opencode.json ~/.config/opencode/
```

### Setup API Tokens

```bash
# Add to ~/.zshrc or ~/.bashrc
export FIGMA_PERSONAL_TOKEN='figd_your-token'
export ATLASSIAN_API_TOKEN='your-token'
export ATLASSIAN_EMAIL='your.email@example.com'
```

Get your tokens:
- **Figma**: https://www.figma.com/developers/api#access-tokens
- **Atlassian**: https://id.atlassian.com/manage-profile/security/api-tokens

## Quick Start

### Option 1: Automatic Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/bouwerp/agentic-framework.git
cd agentic-framework

# Run the installer
./scripts/install.sh
```

The installer will:
- Copy agents, tools, and skills to your opencode config
- Optionally merge the configuration
- Provide setup instructions for API tokens

### Option 2: Manual Installation

```bash
# Copy agents
cp -r .opencode/agents ~/.config/opencode/

# Copy tools
cp -r .opencode/tools ~/.config/opencode/

# Copy skills
cp -r .opencode/skills ~/.config/opencode/

# Copy configuration
cp opencode.json ~/.config/opencode/
```

### Setup API Tokens

```bash
# Add to ~/.zshrc or ~/.bashrc
export FIGMA_PERSONAL_TOKEN='figd_your-token'
export ATLASSIAN_API_TOKEN='your-token'
export ATLASSIAN_EMAIL='your.email@example.com'
```

Get your tokens:
- **Figma**: https://www.figma.com/developers/api#access-tokens
- **Atlassian**: https://id.atlassian.com/manage-profile/security/api-tokens

## Architecture

```
┌─────────────────┐
│  Orchestrator   │ (Primary Agent - Kimi 2.5)
│                 │
│  • Plans        │
│  • Delegates    │
│  • Coordinates  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌───────────┐
│ Worker  │ │ Validator │
│         │ │           │
│ Qwen    │ │ Qwen      │
│ Coder   │ │ Coder     │
│         │ │           │
│ • GSR   │ │ • Reviews │
│ • Figma │ │ • Design  │
│ • Code  │ │   Validation│
└─────────┘ └───────────┘
```

## Agents

### Orchestrator (Primary Agent)

| Property | Value |
|----------|-------|
| **Model** | `openrouter/moonshotai/kimi-k2.5` |
| **Fallback** | `openrouter/moonshotai/kimi-k2` |
| **Mode** | Primary (user-facing) |
| **Role** | Task breakdown, delegation, coordination |
| **Key Tools** | `task`, `read`, `bash` (with approval) |

### Worker (Subagent)

| Property | Value |
|----------|-------|
| **Model** | `openrouter/qwen/qwen3-coder-plus` |
| **Fallback** | `openrouter/qwen/qwen3-coder` |
| **Mode** | Subagent (invoked by Orchestrator) |
| **Role** | Implementation and large-scale refactors |
| **Key Tools** | `write`, `edit`, `bash`, `gsr`, `figma-rest`, `figma-oauth` |
| **Permissions** | Full write/edit/bash access |

### Validator (Subagent)

| Property | Value |
|----------|-------|
| **Model** | `openrouter/qwen/qwen3-coder-plus` |
| **Fallback** | `openrouter/qwen/qwen3-coder` |
| **Mode** | Subagent (invoked by Orchestrator) |
| **Role** | Quality assurance and approval |
| **Key Tools** | `read`, `gsr`, `grep`, `figma-rest` |
| **Permissions** | Read-only (no write/edit), git commands allowed |

## Tools

### GSR (Global Search & Replace)

The custom `gsr` tool performs precise, large-scale code refactors across the entire repository.

**Arguments:**

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `search` | string | required | Text or regex pattern to search for |
| `replace` | string | required | Replacement text (use $1, $2 for capture groups) |
| `pattern` | string | `**/*` | Glob pattern for files to search |
| `includeRegex` | boolean | `false` | Treat search as regex |
| `dryRun` | boolean | `false` | **Preview mode** - show changes without applying |
| `ignoreCase` | boolean | `false` | Case-insensitive search |
| `wholeWord` | boolean | `false` | Match whole words only |

**Example Usage:**

```typescript
// Preview: rename function across all TypeScript files
gsr({
  search: "oldFunctionName",
  replace: "newFunctionName",
  pattern: "**/*.ts",
  wholeWord: true,
  dryRun: true
})

// Apply after review
gsr({
  search: "oldFunctionName",
  replace: "newFunctionName",
  pattern: "**/*.ts",
  wholeWord: true,
  dryRun: false
})
```

### Figma Tools

**REST API Tools (`figma-rest.ts`):**
- `get_file` - Get Figma file structure
- `get_node` - Get specific node details
- `get_image` - Get rendered screenshot
- `get_variables` - Extract design tokens
- `get_comments` - Get file comments

**OAuth Tools (`figma-oauth.ts`):**
- `figma_oauth_url` - Generate OAuth URL for headless auth
- `figma_oauth_token` - Exchange code for tokens
- `figma_oauth_refresh` - Refresh expired tokens
- `figma_whoami` - Verify authentication

**Setup:**
```bash
export FIGMA_PERSONAL_TOKEN='figd_your-token'
```

## Workflows

### Standard Code Changes

1. **User** provides task to Orchestrator
2. **Orchestrator** breaks down task and delegates to Worker
3. **Worker** implements:
   - Single/few files: uses `write`/`edit` tools
   - Many files: uses `gsr` with `dryRun: true` first
4. **Worker** applies GSR changes after preview looks correct
5. **Orchestrator** requests validation from Validator
6. **Validator** reviews GSR preview output and verifies changes
7. **Validator** approves or rejects with feedback
8. **Orchestrator** either completes task or sends back to Worker

### Figma Design Implementation

1. **User** provides Figma URL and requirements
2. **Orchestrator** delegates to Worker with design specs
3. **Worker** extracts design data:
   - `get_variables` - Extract design tokens (colors, spacing, typography)
   - `get_node` - Get component structure
   - `get_image` - Get visual reference screenshot
4. **Worker** implements code based on design
5. **Validator** validates implementation:
   - Compare colors against design tokens
   - Verify spacing matches token values
   - Check visual fidelity against screenshot
   - Search for hardcoded values that should use tokens
6. **Validator** approves or requests fixes
7. **Orchestrator** reports completion or iterates

**Example:**
```bash
opencode run "Implement the login page from this Figma design: https://www.figma.com/file/ABC123?node-id=456-789"
```

## Model Tiering

All agents use OpenRouter models with automatic fallback:

| Agent | Primary Model | Fallback Model |
|-------|--------------|----------------|
| **Orchestrator** | `kimi-k2.5` | `kimi-k2` |
| **Worker** | `qwen3-coder-plus` | `qwen3-coder` |
| **Validator** | `qwen3-coder-plus` | `qwen3-coder` |

**Switch tiers manually:** Use the `variant_cycle` keybind in the TUI.

## Installation

1. Copy `.opencode/` directory to your project root
2. Add `opencode.json` to your project root
3. Start opencode: `opencode run "your task"`

## Project Structure

```
.opencode/
├── agents/
│   ├── orchestrator.md    # Primary coordinator (Kimi 2.5)
│   ├── worker.md          # Implementation (Qwen Coder)
│   └── validator.md       # Review (Qwen Coder)
├── tools/
│   ├── gsr.ts             # Global Search & Replace
│   ├── figma-rest.ts      # Figma REST API
│   └── figma-oauth.ts     # Figma OAuth
└── skills/
    ├── figma-interaction/ # Universal Figma skill
    ├── jira/              # JIRA integration
    └── confluence/        # Confluence integration

opencode.json              # Agent + model configuration
README.md                  # This file
```

## Configuration

Edit `opencode.json` to customize:
- Model selections per agent
- Temperature and step limits
- Tool permissions
- Model variants for tiering

## Example Usage

```bash
# GSR refactor
opencode run "Rename all instances of 'getUser' to 'fetchUser' across the codebase"

# Figma implementation
opencode run "Implement the login page from this Figma: https://www.figma.com/file/ABC123?node-id=456-789"

# With Plan mode (recommended)
opencode run --mode=plan "Add dark mode toggle to settings page"
```

## License

MIT
