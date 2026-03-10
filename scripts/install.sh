#!/bin/bash

# Orchestrator-Worker-Validator Framework Installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Orchestrator-Worker-Validator Framework Installer    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect opencode config directory
if [ -n "$OPENCODE_CONFIG" ]; then
    OPENCODE_DIR="$OPENCODE_CONFIG"
elif [ -d "$HOME/.config/opencode" ]; then
    OPENCODE_DIR="$HOME/.config/opencode"
elif [ -d "$HOME/.opencode" ]; then
    OPENCODE_DIR="$HOME/.opencode"
else
    echo -e "${YELLOW}Warning: Could not find opencode config directory${NC}"
    echo "Creating at ~/.config/opencode"
    mkdir -p "$HOME/.config/opencode"
    OPENCODE_DIR="$HOME/.config/opencode"
fi

echo -e "${GREEN}✓${NC} Found opencode config: ${OPENCODE_DIR}"
echo ""

echo -e "${YELLOW}Step 1/4: Creating directories...${NC}"
mkdir -p "$OPENCODE_DIR/agents"
mkdir -p "$OPENCODE_DIR/tools"
mkdir -p "$OPENCODE_DIR/skills"
echo -e "${GREEN}✓${NC} Directories created"
echo ""

echo -e "${YELLOW}Step 2/4: Installing agents...${NC}"
cp "$PROJECT_ROOT/.opencode/agents/orchestrator.md" "$OPENCODE_DIR/agents/"
cp "$PROJECT_ROOT/.opencode/agents/worker.md" "$OPENCODE_DIR/agents/"
cp "$PROJECT_ROOT/.opencode/agents/validator.md" "$OPENCODE_DIR/agents/"
echo -e "${GREEN}✓${NC} Agents installed:"
echo "  - orchestrator.md (Kimi 2.5)"
echo "  - worker.md (Qwen Coder)"
echo "  - validator.md (Qwen Coder)"
echo ""

echo -e "${YELLOW}Step 3/4: Installing tools...${NC}"
cp "$PROJECT_ROOT/.opencode/tools/gsr.ts" "$OPENCODE_DIR/tools/"
cp "$PROJECT_ROOT/.opencode/tools/figma-rest.ts" "$OPENCODE_DIR/tools/"
cp "$PROJECT_ROOT/.opencode/tools/figma-oauth.ts" "$OPENCODE_DIR/tools/"
echo -e "${GREEN}✓${NC} Tools installed:"
echo "  - gsr.ts (Global Search & Replace)"
echo "  - figma-rest.ts (Figma REST API)"
echo "  - figma-oauth.ts (Figma OAuth)"
echo ""

echo -e "${YELLOW}Step 4/4: Installing skills...${NC}"
if [ -d "$PROJECT_ROOT/.opencode/skills/figma-interaction" ]; then
    cp -r "$PROJECT_ROOT/.opencode/skills/figma-interaction" "$OPENCODE_DIR/skills/"
    echo "  ✓ figma-interaction"
fi
if [ -d "$PROJECT_ROOT/.opencode/skills/jira" ]; then
    cp -r "$PROJECT_ROOT/.opencode/skills/jira" "$OPENCODE_DIR/skills/"
    echo "  ✓ jira"
fi
if [ -d "$PROJECT_ROOT/.opencode/skills/confluence" ]; then
    cp -r "$PROJECT_ROOT/.opencode/skills/confluence" "$OPENCODE_DIR/skills/"
    echo "  ✓ confluence"
fi
echo ""

echo -e "${YELLOW}Optional: Update opencode.json configuration?${NC}"
echo "This will add agent definitions and model configurations."
read -p "Update opencode.json? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$OPENCODE_DIR/opencode.json" ]; then
        cp "$OPENCODE_DIR/opencode.json" "$OPENCODE_DIR/opencode.json.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${GREEN}✓${NC} Backed up existing config"
    fi
    cp "$PROJECT_ROOT/opencode.json" "$OPENCODE_DIR/opencode.json"
    echo -e "${GREEN}✓${NC} Configuration updated"
fi
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Installation Complete!                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓${NC} Framework installed to: ${OPENCODE_DIR}"
echo ""
echo "Next steps:"
echo "1. Set your API tokens:"
echo "   export FIGMA_PERSONAL_TOKEN='figd_your-token'"
echo "   export ATLASSIAN_API_TOKEN='your-token'"
echo "2. Restart opencode or reload your shell"
echo "3. Test with: opencode run \"Hello\""
echo ""
echo "Run ./scripts/verify.sh to verify the installation"
echo ""
