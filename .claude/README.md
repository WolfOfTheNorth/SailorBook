# Claude Code Configuration for SailorBook

## 📁 Directory Structure

```
.claude/
├── README.md              # This file - Configuration overview
├── agents/                # Specialized AI agent guides
│   ├── ai-orchestration.md   # Multi-agent coordination
│   ├── linting.md           # Code quality and formatting
│   ├── playwright.md        # E2E testing with Playwright
│   ├── testing.md           # Unit testing strategies
│   └── ui-ux.md            # Design system and Material 3
└── config/                # Claude Code configurations
```

## 🤖 Agent Specializations

### Core Development Agents
- **ai-orchestration.md**: Multi-agent coordination, task delegation, workflow management
- **linting.md**: Code quality standards, formatting rules, style enforcement
- **testing.md**: Unit testing patterns, TDD practices, test organization

### Specialized Domain Agents
- **playwright.md**: E2E testing strategies, test automation, CI/CD integration
- **ui-ux.md**: Material 3 design system, accessibility, responsive design

## 🎯 Usage Guidelines

### For Claude Agents
1. **Read Main Guide First**: Always check `/CLAUDE.md` for overall project context
2. **Consult Specialized Guides**: Use relevant agent files for domain-specific tasks
3. **Follow Coordination Patterns**: Reference `ai-orchestration.md` for multi-agent work
4. **Maintain Consistency**: Follow established patterns across all guides

### For Developers
1. **Update Agent Guides**: Keep specialized guides current with code changes
2. **Follow Established Patterns**: Use agent guides as authoritative references
3. **Cross-Reference**: Ensure consistency between main guide and specialized guides

## 🔗 Integration with Main Project

### Main Documentation
- **Root CLAUDE.md**: Primary AI development guide with project overview
- **FEATURES.md**: Core feature roadmap and implementation priorities
- **README.md**: General project setup and information

### Specialized Documentation
- **tests/playwright/**: E2E test specifications and analysis
- **PRD.md**: Product requirements and user stories
- **CHANGELOG.md**: Project version history

## 📋 Maintenance

- **Update Frequency**: As code patterns change or new features are added
- **Version Control**: All guide changes should be committed with related code
- **Consistency Checks**: Ensure agent guides align with main CLAUDE.md

---

**Last Updated**: 2025-08-28  
**Maintainer**: Development Team  
**Status**: Active Configuration