#!/bin/bash

# Verify Framework Installation

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Framework Installation Verification ==="
echo ""

# Check opencode config directory
if [ -d "$HOME/.config/opencode" ]; then
    OPENCODE_DIR="$HOME/.config/opencode"
    echo -e "${GREEN}✓${NC} Found opencode config: $OPENCODE_DIR"
else
    echo -e "${RED}✗${NC} opencode config not found"
    exit 1
fi

# Check agents
echo ""
echo "Checking agents..."
for agent in orchestrator worker validator; do
    if [ -f "$OPENCODE_DIR/agents/$agent.md" ]; then
        echo -e "${GREEN}  ✓${NC} $agent.md"
    else
        echo -e "${RED}  ✗${NC} $agent.md (missing)"
    fi
done

# Check tools
echo ""
echo "Checking tools..."
for tool in gsr figma-rest figma-oauth; do
    if [ -f "$OPENCODE_DIR/tools/$tool.ts" ]; then
        echo -e "${GREEN}  ✓${NC} $tool.ts"
    else
        echo -e "${RED}  ✗${NC} $tool.ts (missing)"
    fi
done

# Check skills
echo ""
echo "Checking skills..."
for skill in figma-interaction jira confluence; do
    if [ -d "$OPENCODE_DIR/skills/$skill" ]; then
        echo -e "${GREEN}  ✓${NC} $skill/"
    else
        echo -e "${YELLOW}  ○${NC} $skill/ (optional)"
    fi
done

# Check environment variables
echo ""
echo "Checking environment variables..."
if [ -n "$FIGMA_PERSONAL_TOKEN" ]; then
    echo -e "${GREEN}  ✓${NC} FIGMA_PERSONAL_TOKEN is set"
else
    echo -e "${YELLOW}  ○${NC} FIGMA_PERSONAL_TOKEN (not set, required for Figma)"
fi

if [ -n "$ATLASSIAN_API_TOKEN" ]; then
    echo -e "${GREEN}  ✓${NC} ATLASSIAN_API_TOKEN is set"
else
    echo -e "${YELLOW}  ○${NC} ATLASSIAN_API_TOKEN (not set, required for JIRA/Confluence)"
fi

# Check opencode.json
echo ""
echo "Checking configuration..."
if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    if grep -q "orchestrator" "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}  ✓${NC} opencode.json has agent configuration"
    else
        echo -e "${YELLOW}  ○${NC} opencode.json exists but may need updates"
    fi
else
    echo -e "${YELLOW}  ○${NC} opencode.json not found (using defaults)"
fi

echo ""
echo "=== Verification Complete ==="
echo ""
echo "To test the framework:"
echo "  opencode run \"Hello, I'm the Orchestrator\""
echo ""
