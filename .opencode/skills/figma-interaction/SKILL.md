---
name: figma-interaction
description: This skill should be used when the user asks to "generate code from Figma", "extract design tokens", "view Figma design", "create design system docs", or works with Figma designs. Provides guidance on using Figma MCP server (primary) and REST API (fallback) with OAuth and PAT authentication.
version: 1.0.0
---

# Figma Interaction

This skill provides guidance on interacting with Figma designs via the official MCP server (primary) and REST API (fallback).

## Overview

Use this skill when:
- Generating code from Figma designs (React, Vue, iOS, etc.)
- Extracting design tokens (colors, spacing, typography)
- Creating design system documentation
- Viewing Figma file structure and metadata
- Taking screenshots for visual reference
- Working with Figma MCP server or REST API

## Authentication Setup

### Option 1: Personal Access Token with REST API Tools (Recommended for opencode)

**Note**: The Figma MCP server requires OAuth authentication. For opencode, we recommend using the custom REST API tools (`figma-rest.ts`) with a Personal Access Token instead.

**Step 1: Generate Token**
1. Go to: https://www.figma.com/developers/api#access-tokens
2. Click "Get personal access token"
3. Copy the token (starts with `figd_`)

**Step 2: Set Environment Variable**
```bash
# Add to ~/.zshrc or ~/.bashrc for persistence
export FIGMA_PERSONAL_TOKEN='figd_your-token-here'
```

**Step 3: Use REST API Tools**
Available tools: `get_file`, `get_node`, `get_image`, `get_variables`, `get_comments`

**Benefits:**
- ✅ No browser OAuth flow
- ✅ Token managed in environment (works in CI/CD)
- ✅ Direct API access with full control
- ✅ Works in opencode without OAuth

**Limitations:**
- ⚠️ No `get_design_context` (code generation) - you get raw Figma data
- ⚠️ Manual parsing of node structures required

### Option 2: OAuth with Figma MCP Server

If you need `get_design_context` for code generation, use the official MCP server with OAuth:

**Configuration:**
```json
{
  "mcp": {
    "figma": {
      "type": "remote",
      "url": "https://mcp.figma.com/mcp",
      "oauth": {},
      "enabled": true
    }
  }
}
```

**Authenticate:**
```bash
opencode mcp auth figma
```

This opens a browser for OAuth authorization.

**Benefits:**
- ✅ `get_design_context` - generates React+Tailwind code automatically
- ✅ `get_variable_defs` - extracts design tokens
- ✅ All official Figma MCP tools
- ✅ Automatic token refresh

**Limitations:**
- ⚠️ Requires browser OAuth flow
- ⚠️ Tokens stored in opencode-specific location
- ⚠️ Not portable to other tools

### Option 3: Use Claude Code for Figma Operations

Claude Code has excellent Figma MCP support:

```bash
# Install Figma plugin
claude plugin install figma@claude-plugins-official

# Use Figma
claude "Generate code from this Figma: <url>"
```

Then use opencode for other tasks (GSR, JIRA, Confluence).

### REST API Tools (Custom Implementation)

If you want direct REST API access (without MCP overhead), use the custom `figma-rest` tools:

- `get_file` - Get file structure
- `get_node` - Get specific node
- `get_image` - Get rendered image
- `get_variables` - Get design tokens
- `get_comments` - Get file comments

These use the same `FIGMA_PERSONAL_TOKEN` environment variable but bypass the MCP server entirely.

**When to use REST API tools instead of MCP:**
- MCP server is unavailable or slow
- You need fine-grained control over API calls
- Working in environments where MCP isn't supported
- Want to reduce context size (MCP adds tool descriptions)

**Credential Helper Function:**
```bash
get_figma_credentials() {
  # Check if MCP is configured and authenticated
  if [ -f "$HOME/.local/share/opencode/mcp-auth.json" ]; then
    if grep -q "figma" "$HOME/.local/share/opencode/mcp-auth.json"; then
      echo "MCP"
      return 0
    fi
  fi
  
  # Fallback to PAT
  if [ -n "$FIGMA_PERSONAL_TOKEN" ]; then
    echo "$FIGMA_PERSONAL_TOKEN"
    return 0
  fi
  
  # Ask user
  echo "Figma credentials not found. Please provide your Figma Personal Access Token:"
  echo "Generate one at: https://www.figma.com/developers/api#access-tokens"
  read -s TOKEN
  echo "$TOKEN"
}
```

## Figma MCP Server Tools

The official Figma MCP server provides these tools:

### 1. `get_design_context` (Primary Tool)

**Purpose**: Get structured React + Tailwind code from Figma frames

**Supported file types**: Figma Design, Figma Make

**Usage**:
```
"Generate React code from this Figma frame: <figma-url>"
"Implement this design in Vue with Tailwind: <figma-url>"
"Create iOS SwiftUI code from this frame: <figma-url>"
```

**Customization**:
- Change framework: "Generate in Vue/React Native/SwiftUI"
- Use your components: "Use components from src/components/ui"
- Styling: "Style with Tailwind/Chakra UI/Material UI"

**Example Workflow**:
1. Copy Figma frame URL (e.g., `https://www.figma.com/file/ABC123/Login-Page?node-id=456-789`)
2. Prompt: "Implement the design from this Figma frame using React + Tailwind: <url>"
3. MCP extracts node ID and returns structured code
4. Review generated code against screenshot
5. Adjust framework/styling as needed

**Output Structure**:
```json
{
  "code": "React component code",
  "screenshot": "Image URL for visual reference",
  "variables": ["color-primary", "spacing-md", ...],
  "components": ["Button", "Card", "Input", ...]
}
```

### 2. `get_variable_defs`

**Purpose**: Extract design tokens (colors, spacing, typography)

**Supported file types**: Figma Design

**Usage**:
```
"Get all design tokens from this Figma file: <figma-url>"
"Extract color and spacing variables: <figma-url>"
"List typography styles used in this frame: <figma-url>"
```

**Output**:
```json
{
  "colors": {
    "primary": "#007AFF",
    "secondary": "#5856D6",
    "background": "#FFFFFF"
  },
  "spacing": {
    "sm": "8px",
    "md": "16px",
    "lg": "24px"
  },
  "typography": {
    "heading-lg": { "size": "32px", "weight": "700", "line-height": "1.2" },
    "body": { "size": "16px", "weight": "400", "line-height": "1.5" }
  }
}
```

**Use Cases**:
- Create design token files (`tokens.json`)
- Generate CSS custom properties
- Document design system
- Ensure consistency across codebase

### 3. `get_code_connect_map`

**Purpose**: Get mappings between Figma components and code components

**Supported file types**: Figma Design

**Usage**:
```
"Get Code Connect mappings for this file: <figma-url>"
"Show which Figma components are linked to code: <figma-url>"
```

**Output**:
```json
{
  "node-123": {
    "codeConnectSrc": "src/components/ui/Button.tsx",
    "codeConnectName": "Button"
  },
  "node-456": {
    "codeConnectSrc": "src/components/ui/Card.tsx",
    "codeConnectName": "Card"
  }
}
```

**Note**: Requires Code Connect setup in Figma. If not configured, components will be generated from scratch.

### 4. `get_screenshot`

**Purpose**: Take screenshot of Figma selection for visual reference

**Supported file types**: Figma Design, FigJam

**Usage**:
```
"Get a screenshot of this frame for reference: <figma-url>"
```

**Use Cases**:
- Preserve layout fidelity
- Visual comparison during implementation
- Documentation
- Large designs where full context is too large

### 5. `get_metadata`

**Purpose**: Get XML metadata for large designs (lightweight alternative to `get_design_context`)

**Supported file types**: Figma Design

**Usage**:
```
"Get metadata for this large design: <figma-url>"
"List all layers in this Figma file: <figma-url>"
```

**Output**: XML structure with layer IDs, names, types, positions, sizes

**When to Use**:
- Very large designs (>100 layers)
- `get_design_context` times out or truncates
- Need high-level structure before diving into details
- Multiple selections or entire page

**Workflow for Large Designs**:
1. Run `get_metadata` to get node map
2. Identify specific nodes to implement
3. Run `get_design_context` on selected nodes only
4. Get `get_screenshot` for visual reference

### 6. `create_design_system_rules`

**Purpose**: Generate agent rules for design system consistency

**Supported file types**: No file context required

**Usage**:
```
"Create design system rules for this project"
"Generate agent instructions for Figma implementation"
```

**Output**: Markdown rules file with:
- Required implementation flow
- Component usage guidelines
- Token/variable usage
- Layout primitives
- File organization
- Naming conventions

**Save Location**: `.opencode/rules/figma-design-system.md` or `docs/design-system-rules.md`

**Example Output**:
```markdown
# Figma MCP Integration Rules

## Required Flow
1. Run get_design_context first for structured representation
2. If response is too large, use get_metadata to get node map
3. Run get_screenshot for visual reference
4. Translate React+Tailwind output to project conventions
5. Validate against Figma for 1:1 parity

## Implementation Rules
- Use components from /src/components/ui when possible
- Prioritize Figma fidelity
- Avoid hardcoded values, use design tokens
- Follow WCAG accessibility requirements
- Validate final UI against Figma screenshot
```

### 7. `generate_diagram` (FigJam)

**Purpose**: Generate FigJam diagrams from Mermaid syntax

**Supported file types**: No file context required

**Usage**:
```
"Create a flowchart for user authentication using FigJam"
"Generate a sequence diagram for payment processing"
```

**Supported Diagram Types**:
- Flowcharts
- Gantt charts
- State diagrams
- Sequence diagrams

**Output**: FigJam file with generated diagram

---

## REST API Fallback

When MCP server is unavailable, use the Figma REST API directly.

### Base URLs

- **Standard**: `https://api.figma.com`
- **Figma for Government**: `https://api.figma-gov.com`

### Authentication

```bash
FIGMA_TOKEN="$FIGMA_PERSONAL_TOKEN"

# All requests require this header
-H "X-Figma-Token: $FIGMA_TOKEN"
```

### Key Endpoints

#### 1. Get File

```bash
FILE_KEY="abc123xyz"  # Extract from Figma URL

curl -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY" \
  -H "Accept: application/json" | jq .
```

**Extract File Key from URL**:
- URL: `https://www.figma.com/file/FILE_KEY/Node-Name?node-id=123-456`
- File Key: `FILE_KEY`

#### 2. Get Specific Nodes

```bash
NODE_IDS="456-789,123-456"  # Comma-separated node IDs

curl -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$NODE_IDS" \
  -H "Accept: application/json" | jq .
```

**Extract Node ID from URL**:
- URL parameter: `?node-id=456-789`
- Node ID: `456-789`

#### 3. Get Images

```bash
NODE_ID="456-789"

curl -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/images/$FILE_KEY?ids=$NODE_ID&scale=2" \
  -H "Accept: application/json" | jq .
```

**Parameters**:
- `scale`: 1, 2, 3, or 4 (resolution multiplier)
- `format`: png, jpg, svg, or webp
- `svg_outline_text`: true/false (for SVG)

#### 4. Get Comments

```bash
curl -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/comments" \
  -H "Accept: application/json" | jq .
```

#### 5. Get Variables

```bash
curl -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/variables/local" \
  -H "Accept: application/json" | jq .
```

### REST API Example: Generate Code from Design

```bash
#!/bin/bash

# Configuration
FIGMA_TOKEN="$FIGMA_PERSONAL_TOKEN"
FILE_KEY="abc123xyz"
NODE_ID="456-789"

# Get node data
NODE_DATA=$(curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$NODE_ID" \
  -H "Accept: application/json")

# Extract node name and type
NODE_NAME=$(echo "$NODE_DATA" | jq -r ".nodes[\"$NODE_ID\"].name")
NODE_TYPE=$(echo "$NODE_DATA" | jq -r ".nodes[\"$NODE_ID\"].type")

echo "Processing: $NODE_NAME (Type: $NODE_TYPE)"

# Get image for reference
IMAGE_URL=$(echo "$NODE_DATA" | jq -r ".nodes[\"$NODE_ID\"].image_url")
echo "Image URL: $IMAGE_URL"

# Parse node structure and generate code
# (This is a simplified example - full implementation would parse the node tree)
echo "Generating React component..."
```

---

## Workflow Patterns

### Pattern 1: Generate Code from Design (Recommended)

**Steps**:
1. **Select frame in Figma** and copy URL
   - URL format: `https://www.figma.com/file/FILE_KEY/Name?node-id=NODE_ID`

2. **Prompt with framework specification**:
   ```
   Implement this design from <figma-url> using React + Tailwind.
   Use components from src/components/ui where possible.
   ```

3. **Review generated code**:
   - Check against screenshot
   - Verify component usage
   - Validate design token usage

4. **Iterate if needed**:
   ```
   Adjust the spacing to match the design tokens
   Use the primary color variable instead of hardcoded value
   ```

**Example Prompts**:
```
"Generate React code from this Figma frame: https://www.figma.com/file/ABC123/Login?node-id=456-789"

"Create Vue 3 component with Composition API from this design: <url>"

"Implement this in React Native for iOS: <url>"

"Use Chakra UI instead of Tailwind for this frame: <url>"
```

### Pattern 2: Extract Design Tokens

**Steps**:
1. **Prompt**:
   ```
   Extract all design tokens from this Figma file: <url>
   Include colors, spacing, typography, and effects.
   ```

2. **Review extracted tokens**:
   - Verify all colors are captured
   - Check spacing scale
   - Validate typography styles

3. **Generate token files**:
   ```
   Create a tokens.json file with these design tokens
   Generate CSS custom properties from these tokens
   ```

**Example Output Structure**:
```json
{
  "colors": {
    "brand": {
      "primary": { "value": "#007AFF", "type": "color" },
      "secondary": { "value": "#5856D6", "type": "color" }
    },
    "semantic": {
      "background": { "value": "#FFFFFF", "type": "color" },
      "text": { "value": "#1D1D1F", "type": "color" }
    }
  },
  "spacing": {
    "xs": { "value": "4px", "type": "spacing" },
    "sm": { "value": "8px", "type": "spacing" },
    "md": { "value": "16px", "type": "spacing" },
    "lg": { "value": "24px", "type": "spacing" },
    "xl": { "value": "32px", "type": "spacing" }
  },
  "typography": {
    "heading-lg": {
      "fontSize": { "value": "32", "type": "fontSize" },
      "fontWeight": { "value": "700", "type": "fontWeight" },
      "lineHeight": { "value": "1.2", "type": "lineHeight" }
    },
    "body": {
      "fontSize": { "value": "16", "type": "fontSize" },
      "fontWeight": { "value": "400", "type": "fontWeight" },
      "lineHeight": { "value": "1.5", "type": "lineHeight" }
    }
  }
}
```

### Pattern 3: Create Design System Documentation

**Steps**:
1. **Generate rules**:
   ```
   Run create_design_system_rules for this project
   ```

2. **Save output**:
   - Save to `.opencode/rules/figma-design-system.md`
   - Or `docs/design-system-rules.md`

3. **Reference in future prompts**:
   ```
   Follow the design system rules in .opencode/rules/figma-design-system.md
   ```

4. **Extract additional documentation**:
   ```
   Document all components used in this Figma file: <url>
   Create a component catalog with usage examples
   ```

**Example Documentation Structure**:
```markdown
# Design System Documentation

## Components
- Button (Primary, Secondary, Tertiary)
- Card (Default, Interactive, Media)
- Input (Text, Email, Password, Search)

## Tokens
- Colors (Brand, Semantic, Status)
- Spacing (4px grid system)
- Typography (Heading, Body, Caption scales)

## Usage Guidelines
- When to use each component
- Accessibility requirements
- Responsive behavior
```

### Pattern 4: Large Design Implementation

**Steps**:
1. **Get metadata first** (lightweight):
   ```
   Get metadata for this large design: <url>
   List all top-level layers
   ```

2. **Identify sections to implement**:
   - Header
   - Main content
   - Sidebar
   - Footer

3. **Implement section by section**:
   ```
   Implement just the header section from this design: <url>
   Now implement the main content area: <url>
   ```

4. **Get screenshots for each section**:
   ```
   Get screenshot of the header for reference
   ```

5. **Assemble into complete page**:
   ```
   Combine the header, main content, and footer into a complete page
   ```

---

## Rate Limits

### MCP Server Rate Limits

**Starter Plan / View or Collab Seats**:
- **6 tool calls per month**
- Very limited - use REST API for heavy usage

**Professional / Organization / Enterprise (Dev or Full seats)**:
- **Tier 1 REST API limits**: 120 requests per minute
- Same as Figma REST API Tier 1

### REST API Rate Limits

| Tier | Requests/Minute | Eligibility |
|------|----------------|-------------|
| Tier 1 | 120 | Professional, Organization, Enterprise |
| Tier 2 | 600 | Enterprise (upon request) |

### Monitoring Usage

```bash
# Check rate limit headers in API responses
curl -I -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/me"

# Response headers:
# X-RateLimit-Limit: 120
# X-RateLimit-Remaining: 115
# X-RateLimit-Reset: 1640000000
```

### Working Within Limits

**For Low-Rate Users (6/month)**:
1. Use MCP tools sparingly
2. Get full context in one call when possible
3. Use `get_metadata` for structure (counts as 1 call)
4. Cache results locally
5. Switch to REST API with PAT for development

**For High-Rate Users**:
1. Batch requests when possible
2. Use node-specific endpoints instead of full file
3. Cache images and assets
4. Implement exponential backoff on 429 errors

---

## Best Practices

### Figma File Structure

**For Better Code Generation**:

1. **Use Components** for anything reused
   - Buttons, cards, inputs, icons
   - Link to code via Code Connect (optional)

2. **Use Variables** for design tokens
   - Colors, spacing, typography, effects
   - Name semantically (`color-primary` not `#007AFF`)

3. **Name Layers Semantically**
   - ✅ `CardContainer`, `SubmitButton`, `UserAvatar`
   - ❌ `Group 5`, `Frame 123`, `Rectangle 8`

4. **Use Auto Layout**
   - Communicates responsive intent
   - Defines spacing and alignment
   - Resize to test behavior before generating

5. **Break Large Screens into Components**
   - Header, Footer, Sidebar as separate frames
   - Implement section by section
   - Easier to debug and iterate

6. **Use Annotations**
   - Add notes for complex interactions
   - Document behavior not visible in design
   - Use dev resources for detailed specs

### Prompt Engineering

**Effective Prompts**:

```
✅ Good: "Generate React + Tailwind code from this Figma frame: <url>. Use components from src/components/ui."

❌ Bad: "Make this design into code" (too vague)

✅ Good: "Extract all design tokens from this file: <url>. Create a tokens.json file."

❌ Bad: "Get variables" (unclear what format)

✅ Good: "Implement just the header section from this design: <url>. Use flexbox for layout."

❌ Bad: "Code this whole page" (too large, may timeout)
```

**Framework-Specific Prompts**:

```
React: "Generate React functional component with hooks from <url>"
Vue: "Create Vue 3 component with Composition API from <url>"
React Native: "Implement in React Native for iOS from <url>"
SwiftUI: "Generate SwiftUI code for iOS from <url>"
Angular: "Create Angular component with TypeScript from <url>"
```

**Styling-Specific Prompts**:

```
Tailwind: "Style with Tailwind CSS utility classes"
Chakra UI: "Use Chakra UI components and theme"
Material UI: "Implement with Material UI v5"
Styled Components: "Use styled-components for styling"
CSS Modules: "Use CSS modules with BEM naming"
```

### Code Quality

**Implementation Guidelines**:

1. **Treat MCP output as a starting point**
   - Translate to project conventions
   - Replace Tailwind with design system tokens
   - Reuse existing components

2. **Validate against Figma**
   - Compare with screenshot
   - Check spacing, colors, typography
   - Test responsive behavior

3. **Avoid Hardcoded Values**
   - Use design tokens from Figma
   - Reference variables, not hex codes
   - Use spacing scale, not pixels

4. **Follow Accessibility**
   - WCAG 2.1 AA minimum
   - Proper heading hierarchy
   - Color contrast ratios
   - Keyboard navigation

5. **Document Components**
   - Add JSDoc/TSDoc comments
   - Document props and usage
   - Include accessibility notes

---

## Troubleshooting

### OAuth Authentication Issues

**Problem**: MCP server returns 401 Unauthorized

**Solutions**:
1. **Re-authenticate**:
   ```bash
   opencode mcp logout figma
   opencode mcp auth figma
   ```

2. **Check token storage**:
   ```bash
   cat ~/.local/share/opencode/mcp-auth.json | grep -A 5 figma
   ```

3. **Verify browser completed flow**:
   - Ensure you authorized in browser
   - Check for redirect back to opencode
   - Try incognito browser if stuck

4. **Fallback to PAT**:
   ```bash
   export FIGMA_PERSONAL_TOKEN='figd_your-token'
   # Use REST API instead of MCP
   ```

### Rate Limit Errors

**Problem**: 429 Too Many Requests

**Solutions**:
1. **Wait and retry**:
   ```bash
   # Check rate limit reset time
   curl -I "https://api.figma.com/v1/me" -H "X-Figma-Token: $TOKEN"
   # Look for X-RateLimit-Reset header
   ```

2. **Reduce request frequency**:
   - Batch operations
   - Cache results locally
   - Use `get_metadata` for structure (lighter)

3. **Upgrade Figma plan**:
   - Starter: 6/month (very limited)
   - Professional: 120/minute
   - Enterprise: Can request higher limits

4. **Use REST API with PAT**:
   - Sometimes MCP has additional overhead
   - Direct API calls may be more efficient

### Large Design Timeouts

**Problem**: `get_design_context` times out or truncates

**Solutions**:
1. **Use `get_metadata` first**:
   ```
   Get metadata for this large design to see the structure
   ```

2. **Implement section by section**:
   ```
   Just implement the header section: <url>
   Now the main content area: <url>
   ```

3. **Reduce selection size**:
   - Select individual frames
   - Avoid selecting entire page
   - Break into logical components

4. **Increase timeout** (if using REST API):
   ```json
   {
     "mcp": {
       "figma": {
         "timeout": 30000  // 30 seconds
       }
     }
   }
   ```

### Missing Design Tokens

**Problem**: Generated code uses hardcoded values instead of tokens

**Solutions**:
1. **Explicitly request tokens**:
   ```
   Extract all design tokens first, then use them in the generated code
   ```

2. **Create token file**:
   ```
   Create a tokens.json file with all colors, spacing, and typography from this Figma file
   ```

3. **Reference in prompt**:
   ```
   Use design tokens from Figma variables, don't hardcode colors or spacing
   ```

4. **Check Figma file**:
   - Ensure variables are defined in Figma
   - Variables should be used in the design
   - Name variables semantically

### Component Reuse Issues

**Problem**: Generated code creates new components instead of reusing existing ones

**Solutions**:
1. **Specify component library**:
   ```
   Use components from src/components/ui for buttons, cards, and inputs
   ```

2. **Set up Code Connect** (optional):
   - Link Figma components to code in Figma
   - MCP will automatically use mapped components

3. **Provide component documentation**:
   ```
   Here are our available components:
   - Button (variants: primary, secondary, outline)
   - Card (variants: default, interactive, media)
   Use these instead of creating new ones
   ```

4. **Review and refactor**:
   - Generate code first
   - Identify duplicated functionality
   - Replace with existing components

---

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `FIGMA_PERSONAL_TOKEN` | Personal Access Token for REST API | `figd_abc123...` |
| `FIGMA_API_URL` | Custom API URL (optional) | `https://api.figma.com` |

**Set in `.env` or shell**:
```bash
export FIGMA_PERSONAL_TOKEN='figd_your-token-here'
```

**In opencode.json**:
```json
{
  "provider": {
    "figma": {
      "options": {
        "apiKey": "{env:FIGMA_PERSONAL_TOKEN}"
      }
    }
  }
}
```

---

## Complete Examples

### Example 1: Full Component Implementation

**User Request**:
```
Implement the login page from this Figma design: https://www.figma.com/file/ABC123/Login-Page?node-id=456-789

Requirements:
- React with TypeScript
- Tailwind CSS for styling
- Use components from src/components/ui
- Include form validation
- Follow accessibility guidelines
```

**Expected Flow**:
1. MCP extracts node ID (456-789) from URL
2. `get_design_context` returns React + Tailwind code
3. `get_screenshot` provides visual reference
4. `get_variable_defs` extracts design tokens
5. Agent translates to project conventions
6. Output: Complete Login.tsx component

### Example 2: Design Token Extraction

**User Request**:
```
Extract all design tokens from this Figma file: https://www.figma.com/file/DEF456/Design-System

Create:
1. tokens.json with all colors, spacing, typography
2. CSS custom properties file
3. TypeScript types for tokens
```

**Expected Flow**:
1. `get_variable_defs` extracts all variables
2. Agent structures into tokens.json
3. Generates CSS custom properties (.css file)
4. Creates TypeScript types (tokens.ts)
5. Output: Three files with design tokens

### Example 3: Design System Documentation

**User Request**:
```
Create comprehensive design system documentation from this Figma file: https://www.figma.com/file/GHI789/Design-System

Include:
- Component catalog with usage examples
- Design token reference
- Accessibility guidelines
- Code snippets for each component
```

**Expected Flow**:
1. `create_design_system_rules` generates base rules
2. `get_design_context` for each component
3. Agent compiles into markdown documentation
4. Output: `docs/design-system.md`

---

## References

- [Figma REST API Documentation](https://www.figma.com/developers/api)
- [Figma MCP Server Guide](https://github.com/figma/mcp-server-guide)
- [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) (for comparison)
- [Code Connect Documentation](https://help.figma.com/hc/en-us/articles/23920389749655-Code-Connect)
- [Figma Rate Limits](https://www.figma.com/developers/api#rate-limits)

## Syncing to Other AI Tools

This skill should be synced to other AI assistant tools (Claude Code, Gemini, Codex, etc.) using the skill-manager skill.

### Syncing Command

```bash
# Using skill-manager to sync to all tools
./scripts/sync-skills.sh --source ~/.config/opencode/skills/figma-interaction
```
