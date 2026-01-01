# Skills

A collection of [Agent Skills](https://agentskills.io) for AI coding assistants like GitHub Copilot, Anthropic Claude, and OpenAI Codex.

## What Are Skills?

Skills are portable, reusable instructions that teach AI agents how to perform specific tasks. They follow the open [Agent Skills specification](https://agentskills.io/specification), making them compatible across multiple AI platforms.

Each skill is a directory containing:
- `SKILL.md` - Required file with YAML frontmatter (metadata) and Markdown body (instructions)
- `scripts/` - Optional helper scripts
- `references/` - Optional reference materials
- `assets/` - Optional supporting files

## Available Skills

| Skill | Description |
|-------|-------------|
| [issue-triage](./issue-triage/) | Fetch and organize GitHub issues to identify what to work on next |
| [issue-closer](./issue-closer/) | Close GitHub issues with appropriate reasoning to reduce open issue count |
| [issue-responder](./issue-responder/) | Add comments to GitHub issues to request info or provide updates |
| [issue-labeler](./issue-labeler/) | Add, remove, or update labels on GitHub issues for organization |

### Issue Management Workflow

These skills work together to help you manage and reduce open issues. See [WORKFLOW.md](./WORKFLOW.md) for a complete guide on using these skills together, including:

- Complete triage-to-closure workflow
- Common patterns for cleanup sessions
- Automation examples
- Tips for effective issue management

## Adding a New Skill

### 1. Create the Directory Structure

```bash
mkdir -p my-skill-name
touch my-skill-name/SKILL.md
```

### 2. Write Your SKILL.md

Every skill requires a `SKILL.md` file with:

**YAML Frontmatter (required fields):**
```yaml
---
name: my-skill-name
description: A clear description of what this skill does and when to use it.
---
```

**Optional frontmatter fields:**
- `license` - License identifier (e.g., `MIT`, `Apache-2.0`)
- `compatibility` - Environment requirements (e.g., `Requires git and curl`)
- `metadata` - Key-value pairs for author, version, etc.
- `allowed-tools` - Space-separated list of pre-approved tools

**Markdown Body:**
After the frontmatter, include detailed instructions, examples, and any context the AI agent needs to execute the skill.

### 3. Naming Conventions

- Use lowercase letters, numbers, and hyphens only
- 1-64 characters
- Cannot start or end with a hyphen
- No consecutive hyphens
- Directory name must match the `name` field in frontmatter

**Valid:** `pdf-processing`, `api-client`, `test-runner`  
**Invalid:** `PDF-Processing`, `-my-skill`, `my--skill`

### 4. Best Practices

- **Be specific** - Provide clear, step-by-step instructions
- **Include examples** - Show expected inputs and outputs
- **Document edge cases** - Help the agent handle unusual situations
- **Keep it focused** - One skill per task; compose complex workflows from multiple skills
- **Test your skill** - Verify it works with your target AI assistant

## Using Skills

### GitHub Copilot (VS Code)

Place skills in `.github/skills/` in your repository or reference them in your Copilot configuration.

### GitHub Copilot CLI

Skills in the current directory or `.github/skills/` are automatically discovered.

### Anthropic Claude / OpenAI Codex

Reference skills according to each platform's documentation for custom instructions.

## Resources

- [Agent Skills Specification](https://agentskills.io/specification)
- [GitHub Copilot Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io)

## License

MIT
