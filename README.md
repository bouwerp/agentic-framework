# Orchestrator-Worker-Validator Framework

An agentic framework for opencode that implements a three-tier collaboration pattern with a custom **GSR (Global Search & Replace)** tool for large-scale refactors.

## Architecture

```
┌─────────────┐
│Orchestrator │ (Primary Agent)
│  - Plans    │
│  - Delegates│
│  - Coordinates
└──────┬──────┘
       │
       ├────────────┐
       │            │
       ▼            ▼
┌──────────┐  ┌───────────┐
│  Worker  │  │ Validator │
│          │  │           │
│ - Codes  │  │ - Reviews │
│ - GSR    │  │ - GSR     │
│ - Refactors     │ Preview │
└──────────┘  └───────────┘
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
- **Key Tools**: `write`, `edit`, `bash`, `gsr`

### Validator (Subagent)
- **Role**: Quality assurance and approval
- **Model**: Claude Sonnet 4.6 (mid-tier, configurable)
- **Mode**: Subagent (invoked by Orchestrator)
- **Key Tools**: `read`, `gsr` (preview mode), `grep`
- **Permissions**: Read-only (no write/edit)

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

## Installation

1. Copy `.opencode/` directory to your project root
2. Add `opencode.json` to your project root
3. Start opencode: `opencode run "your task"`

## Files

```
.opencode/
├── agents/
│   ├── orchestrator.md  # Primary coordinator agent
│   ├── worker.md        # Implementation agent with GSR
│   └── validator.md     # Review agent with GSR Preview
└── tools/
    └── gsr.ts           # Global Search & Replace tool
opencode.json            # Configuration with model tiering
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
