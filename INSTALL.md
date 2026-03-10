# Installation Guide

## Quick Install

```bash
# Clone the repository
git clone https://github.com/bouwerp/agentic-framework.git
cd agentic-framework

# Run the installer
./scripts/install.sh

# Verify installation
./scripts/verify.sh
```

## What Gets Installed

The installer copies the following to your opencode configuration directory (`~/.config/opencode/`):

### Agents (3)
- `orchestrator.md` - Primary coordinator (Kimi 2.5)
- `worker.md` - Implementation specialist (Qwen Coder)
- `validator.md` - Quality assurance (Qwen Coder)

### Tools (3)
- `gsr.ts` - Global Search & Replace
- `figma-rest.ts` - Figma REST API integration
- `figma-oauth.ts` - Figma OAuth authentication

### Skills (3)
- `figma-interaction/` - Universal Figma integration
- `jira/` - JIRA interaction with ADF support
- `confluence/` - Confluence interaction with ADF support

## Manual Installation

If you prefer to install manually:

```bash
# Copy agents
cp -r .opencode/agents ~/.config/opencode/

# Copy tools
cp -r .opencode/tools ~/.config/opencode/

# Copy skills
cp -r .opencode/skills ~/.config/opencode/

# Copy configuration (optional)
cp opencode.json ~/.config/opencode/
```

## Environment Setup

Add these to your `~/.zshrc` or `~/.bashrc`:

```bash
# Figma Personal Access Token
# Get from: https://www.figma.com/developers/api#access-tokens
export FIGMA_PERSONAL_TOKEN='figd_your-token-here'

# Atlassian API Token (for JIRA/Confluence)
# Get from: https://id.atlassian.com/manage-profile/security/api-tokens
export ATLASSIAN_API_TOKEN='your-token-here'
export ATLASSIAN_EMAIL='your.email@example.com'
export ATLASSIAN_SITE='your-domain.atlassian.net'
```

## Verification

After installation, run:

```bash
./scripts/verify.sh
```

This checks:
- ✓ All agents are installed
- ✓ All tools are installed
- ✓ All skills are installed
- ✓ Environment variables are set
- ✓ Configuration is valid

## Testing

Test the framework with:

```bash
# Basic test
opencode run "Hello, I'm the Orchestrator"

# Test GSR tool
opencode run "Rename all instances of 'foo' to 'bar' in *.js files"

# Test Figma integration (requires token)
opencode run "Get design tokens from Figma file YOUR_FILE_KEY"
```

## Troubleshooting

### Agents not showing up
Restart opencode or reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

### Tools not available
Verify tools are in the correct location:
```bash
ls ~/.config/opencode/tools/
# Should show: figma-oauth.ts  figma-rest.ts  gsr.ts
```

### Permission errors
Make scripts executable:
```bash
chmod +x scripts/install.sh scripts/verify.sh
```

## Uninstall

To remove the framework:

```bash
# Remove agents
rm ~/.config/opencode/agents/orchestrator.md
rm ~/.config/opencode/agents/worker.md
rm ~/.config/opencode/agents/validator.md

# Remove tools
rm ~/.config/opencode/tools/gsr.ts
rm ~/.config/opencode/tools/figma-rest.ts
rm ~/.config/opencode/tools/figma-oauth.ts

# Remove skills
rm -rf ~/.config/opencode/skills/figma-interaction
rm -rf ~/.config/opencode/skills/jira
rm -rf ~/.config/opencode/skills/confluence
```

## Getting Help

- **Documentation**: See [README.md](README.md)
- **Issues**: https://github.com/bouwerp/agentic-framework/issues
- **Discussions**: https://github.com/bouwerp/agentic-framework/discussions
