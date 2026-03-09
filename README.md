# Orchestrator-Worker-Validator Framework

An agentic framework for opencode that implements a three-tier collaboration pattern with:
- **GSR (Global Search & Replace)** for large-scale refactors
- **Figma integration** for design-to-code workflows
- **Dynamic model tiering** for optimal performance

## Architecture

```
┌─────────────┐
│Orchestrator │ (Primary Agent)
│  - Plans    │
│  - Delegates│
│  - Coordinates
└──────┬──────┘
       │
       ├────────────┬──────────────┐
       │            │              │
       ▼            ▼              ▼
┌──────────┐  ┌───────────┐  ┌──────────┐
│  Worker  │  │ Validator │  │  Figma   │
│          │  │           │  │  Tools   │
│ - Codes  │  │ - Reviews │  │          │
│ - GSR    │  │ - GSR     │  │ - REST   │
│ - Figma  │  │ - Design  │  │ - OAuth  │
└──────────┘  └───────────┘  └──────────┘
```
┌─────────────┐
│Orchestrator │ (Primary Agent)
│  - Plans    │
│  - Delegates│
│  - Coordinates
└──────┬──────┘
       │
       ├────────────┬──────────────┐
       │            │              │
       ▼            ▼              ▼
┌──────────┐  ┌───────────┐  ┌──────────┐
│  Worker  │  │ Validator │  │  Figma   │
│          │  │           │  │  Tools   │
│ - Codes  │  │ - Reviews │  │          │
│ - GSR    │  │ - GSR     │  │ - REST   │
│ - Figma  │  │ - Design  │  │ - OAuth  │
└──────────┘  └───────────┘  └──────────┘
```

## Agents

### Orchestrator (Primary)
- **Role**: Task breakdown, delegation, and coordination
- **Model**: Claude Sonnet 4.6 (mid-tier, configurable)
- **Mode**: Primary (user-facing)
- **Key Tools**: `task`, `read`, `bash` (with approval)

### Worker (Subagent)
- **Role**: Implementation and large-scale refactors
- **Model**: Claude Sonnet 4.6 (mid-tier, configurable)
- **Mode**: Subagent (invoked by Orchestrator)
- **Key Tools**: `write`, `edit`, `bash`, `gsr`, `figma-rest`, `figma-oauth`
- **Permissions**: Full write/edit/bash access

### Validator (Subagent)
- **Role**: Quality assurance and approval
- **Model**: Claude Sonnet 4.6 (mid-tier, configurable)
- **Mode**: Subagent (invoked by Orchestrator)
- **Key Tools**: `read`, `gsr`, `grep`, `figma-rest`
- **Permissions**: Read-only (no write/edit), git commands allowed

## GSR Tool (Global Search & Replace)

The custom `gsr` tool performs precise, large-scale code refactors across the entire repository without manually opening each file.

### Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `search` | string | required | Text or regex pattern to search for |
| `replace` | string | required | Replacement text (use $1, $2 for capture groups) |
| `pattern` | string | `**/*` | Glob pattern for files to search |
| `includeRegex` | boolean | `false` | Treat search as regex |
| `dryRun` | boolean | `false` | **Preview mode** - show changes without applying |
| `ignoreCase` | boolean | `false` | Case-insensitive search |
| `wholeWord` | boolean | `false` | Match whole words only |

### GSR Preview Mode

Always run with `dryRun: true` first to preview changes:

```typescript
// Preview: rename function across all TypeScript files
gsr(
  search: "oldFunctionName",
  replace: "newFunctionName",
  pattern: "**/*.ts",
  wholeWord: true,
  dryRun: true    // <-- GSR Preview mode
)

// Apply after review
gsr(
  search: "oldFunctionName",
  replace: "newFunctionName",
  pattern: "**/*.ts",
  wholeWord: true,
  dryRun: false
)
```

### Example Use Cases

```typescript
// 1. Rename a function everywhere
gsr({ search: "getUser", replace: "fetchUser", wholeWord: true, dryRun: true })

// 2. Update import paths with regex
gsr({
  search: "from '\\.\\./utils/(\\w+)'",
  replace: "from '@/utils/$1'",
  includeRegex: true,
  pattern: "**/*.ts",
  dryRun: true
})

// 3. Replace deprecated API
gsr({
  search: "ReactDOM.render",
  replace: "createRoot",
  pattern: "**/*.{tsx,ts}",
  dryRun: true
})

// 4. Change config values across files
gsr({
  search: "API_URL = 'http://localhost:3000'",
  replace: "API_URL = 'https://api.example.com'",
  dryRun: true
})
```

## Dynamic Model Tiering

The framework supports dynamic tiering through model variants:

### Claude Models
```json
{
  "high": { "thinking": { "budgetTokens": 16000 } },
  "medium": { "thinking": { "budgetTokens": 8000 } },
  "low": { "thinking": { "disabled": true } }
}
```

### GPT Models
```json
{
  "high": { "reasoningEffort": "high" },
  "medium": { "reasoningEffort": "medium" },
  "low": { "reasoningEffort": "low" }
}
```

### Switching Tiers
Use the `variant_cycle` keybind in the TUI to switch between model tiers during a session.

## Workflow

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

### Example Figma Workflow

```bash
# User request
opencode run "Implement the login page from this Figma design: https://www.figma.com/file/ABC123?node-id=456-789"

# Framework executes:
# 1. Worker: get_variables --file_key 'ABC123'
# 2. Worker: get_node --file_key 'ABC123' --node_id '456-789'
# 3. Worker: get_image --file_key 'ABC123' --node_id '456-789' --scale 2
# 4. Worker: Implement React component with design tokens
# 5. Validator: Verify implementation matches design tokens
# 6. Validator: Check for hardcoded colors/spacing
# 7. Orchestrator: Report completion
```

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

### Example Figma Workflow

```bash
# User request
opencode run "Implement the login page from this Figma design: https://www.figma.com/file/ABC123?node-id=456-789"

# Framework executes:
# 1. Worker: get_variables --file_key 'ABC123'
# 2. Worker: get_node --file_key 'ABC123' --node_id '456-789'
# 3. Worker: get_image --file_key 'ABC123' --node_id '456-789' --scale 2
# 4. Worker: Implement React component with design tokens
# 5. Validator: Verify implementation matches design tokens
# 6. Validator: Check for hardcoded colors/spacing
# 7. Orchestrator: Report completion
```

## Installation

1. Copy `.opencode/` directory to your project root
2. Add `opencode.json` to your project root
3. Start opencode: `opencode run "your task"`

## Files

```
.opencode/
├── agents/
│   ├── orchestrator.md    # Primary coordinator agent
│   ├── worker.md          # Implementation agent with GSR + Figma
│   └── validator.md       # Review agent with design validation
├── tools/
│   ├── gsr.ts             # Global Search & Replace tool
│   ├── figma-rest.ts      # Figma REST API tools
│   └── figma-oauth.ts     # Figma OAuth authentication tools
├── skills/
│   ├── figma-interaction/ # Universal Figma skill (MCP + REST)
│   ├── jira/              # JIRA interaction skill
│   └── confluence/        # Confluence interaction skill
└── README.md              # This file
opencode.json              # Configuration with agents + model tiering
```
.opencode/
├── agents/
│   ├── orchestrator.md    # Primary coordinator agent
│   ├── worker.md          # Implementation agent with GSR + Figma
│   └── validator.md       # Review agent with design validation
├── tools/
│   ├── gsr.ts             # Global Search & Replace tool
│   ├── figma-rest.ts      # Figma REST API tools
│   └── figma-oauth.ts     # Figma OAuth authentication tools
├── skills/
│   ├── figma-interaction/ # Universal Figma skill (MCP + REST)
│   ├── jira/              # JIRA interaction skill
│   └── confluence/        # Confluence interaction skill
└── README.md              # This file
opencode.json              # Configuration with agents + model tiering
```

## Configuration

Edit `opencode.json` to customize:
- Model selections per agent
- Temperature and step limits
- Tool permissions
- Model variants for tiering

## Example Usage

```bash
# Start with default Orchestrator
opencode run "Rename all instances of 'getUser' to 'fetchUser' across the codebase"

# The framework will:
# 1. Orchestrator delegates to Worker
# 2. Worker runs GSR with dryRun: true to preview
# 3. Worker applies changes after preview looks good
# 4. Validator reviews the GSR preview and output
# 5. Orchestrator reports completion
```

## License

MIT
