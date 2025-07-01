# SuperQ – Development Framework for Amazon Q CLI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.1-blue.svg)](https://github.com/NomenAK/SuperQ)
[![GitHub issues](https://img.shields.io/github/issues/NomenAK/SuperQ)](https://github.com/NomenAK/SuperQ/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/NomenAK/SuperQ/blob/master/CONTRIBUTING.md)

**A configuration framework that enhances Amazon Q CLI with specialized commands, cognitive personas, and development methodologies.**

## 🚀 Version 2.0.1 Update

IMPORTANT: Start Fresh by removing old files and dir in .amazonq (RULES.md TOOLS.md PERSONAS.md Q.md and /commands dir)

SuperQ v2 introduces architectural improvements focused on maintainability and extensibility:

- **⚡ Streamlined Architecture**: @include reference system for configuration management
- **🎭 Personas as Context Hooks**: 9 cognitive personas integrated into the context hooks system (`/context hooks add persona-architect`, `/context hooks add persona-security`, etc.)
- **📦 Enhanced Installer**: install.sh with update mode, dry-run, backup handling, and platform detection
- **🔧 Modular Design**: Template system for adding new commands and features
- **🎯 Unified Experience**: Consistent command behavior across all operations

See [ROADMAP.md](ROADMAP.md) for future development ideas and contribution opportunities.

## 🎯 Background

Amazon Q CLI provides powerful capabilities but can benefit from:
- **Specialized expertise** for different technical domains
- **Token efficiency** for complex projects  
- **Evidence-based approaches** to development
- **Context preservation** during debugging sessions
- **Domain-specific thinking** for various tasks

## ✨ SuperQ Features

SuperQ enhances Amazon Q CLI with:
- **18 Specialized Commands** covering development lifecycle tasks
- **9 Cognitive Personas** for domain-specific approaches
- **Token Optimization** with compression options
- **Evidence-Based Methodology** encouraging documentation
- **Tool Integration** with file system, bash execution, and AWS access
- **Git Checkpoint Support** for safe experimentation
- **Introspection Mode** for framework improvement and troubleshooting

## 🚀 Installation

### Enhanced Installer v2.0.1
The installer provides various options:

```bash
$ git clone https://github.com/NomenAK/SuperQ.git
$ cd SuperQ

# Basic installation
$ ./install.sh                           # Default: ~/.amazonq/

# Advanced options
$ ./install.sh --dir /opt/amazonq        # Custom location
$ ./install.sh --update                  # Update existing installation
$ ./install.sh --dry-run --verbose       # Preview changes with details
$ ./install.sh --force                   # Skip confirmations (automation)
$ ./install.sh --log install.log         # Log all operations
```

**v2.0.1 Installer Features:**
- 🔄 **Update Mode**: Preserves customizations while updating
- 👁️ **Dry Run**: Preview changes before applying
- 💾 **Smart Backups**: Automatic backup with timestamping
- 🧹 **Clean Updates**: Removes obsolete files
- 🖥️ **Platform Detection**: Works with Linux, macOS, WSL
- 📊 **Progress Tracking**: Installation feedback

Zero dependencies. Installs to `~/.amazonq/` by default.

**Note:** After installation, all configuration files are located in `~/.amazonq/` (your home directory), not in the project directory.

## 💡 Core Capabilities

### 🧠 **Cognitive Personas (Now as Context Hooks!)**
Switch between different approaches with persona context hooks:

```bash
Amazon Q> /context hooks add persona-architect     # Systems thinking approach
Amazon Q> /context hooks add persona-frontend      # UX-focused development  
Amazon Q> /context hooks add persona-security      # Security-first analysis
Amazon Q> /context hooks add persona-analyzer      # Root cause analysis approach
```

**v2.0.1 Update**: All 9 personas are now available as context hooks, with both `conversation_start` and `per_prompt` options for consistent access to specialized approaches.

### ⚡ **19 Commands**
Development lifecycle coverage:

**Development Commands**
```bash
$ q chat
Amazon Q> /build --react --tdd                    # Development with AI components
Amazon Q> /dev-setup --ci --monitor               # Environment setup
Amazon Q> /test --coverage --e2e                  # Testing strategies
```

**Analysis & Quality**
```bash
$ q chat
Amazon Q> /review --quality --evidence            # AI-powered code review
Amazon Q> /analyze --architecture                 # System analysis
Amazon Q> /troubleshoot --prod --five-whys        # Issue resolution
Amazon Q> /improve --performance --iterate        # Optimization
Amazon Q> /explain --depth expert --visual        # Documentation
```

**Operations & Security**
```bash
$ q chat
Amazon Q> /deploy --env prod --plan               # Deployment planning
Amazon Q> /scan --security --owasp --deps         # Security audits
Amazon Q> /migrate --dry-run --rollback           # Database migrations
Amazon Q> /cleanup --all --validate               # Maintenance tasks
```

### 🎛️ **Tool Integration**
- **fs_read**: Access to file system for reading
- **fs_write**: File system write capabilities
- **execute_bash**: Command execution capabilities
- **use_aws**: AWS service integration

**⚠️ Important:** SuperQ leverages Amazon Q CLI's built-in tool permissions system. You need to trust these tools using the `/tools` commands to use tool-related functionality.

### 📊 **Token Efficiency**
SuperQ's @include template system helps manage token usage:
- **Compact mode** option for token reduction (`/compact`)
- **Template references** for configuration management
- **Caching mechanisms** to avoid redundancy
- **Context-aware compression** options

## 🎮 Example Workflows

### Enterprise Architecture Flow
```bash
$ q chat
Amazon Q> /context hooks add persona-architect
Amazon Q> /design --api --ddd --bounded-context    # Domain-driven design
Amazon Q> /estimate --detailed --worst-case        # Resource planning
Amazon Q> /context hooks add persona-security
Amazon Q> /scan --security --validate              # Security review
Amazon Q> /context hooks add persona-backend
Amazon Q> /build --api --tdd --coverage            # Implementation
```

### Production Issue Resolution
```bash
$ q chat
Amazon Q> /context hooks add persona-analyzer
Amazon Q> /troubleshoot --investigate --prod       # Analysis
Amazon Q> /analyze --profile --perf               # Performance review
Amazon Q> /context hooks add persona-performance
Amazon Q> /improve --performance --threshold 95%   # Optimization
Amazon Q> /test --integration --e2e               # Validation
```

### Framework Troubleshooting & Improvement
```bash
$ q chat
Amazon Q> /troubleshoot --introspect              # Debug SuperQ behavior
Amazon Q> /analyze --introspect                   # Analyze framework patterns
Amazon Q> /improve --introspect                   # Optimize token usage
Amazon Q> /compact                                # Reduce token usage
```

### Full-Stack Feature Development
```bash
$ q chat
Amazon Q> /context hooks add persona-frontend
Amazon Q> /build --react --watch                  # UI development
Amazon Q> /context hooks add persona-qa
Amazon Q> /test --coverage --e2e --strict         # Quality assurance
Amazon Q> /context hooks add persona-security
Amazon Q> /scan --validate --deps                 # Security check
```

## 🎭 Available Personas

| Persona | Focus Area | Tools | Use Cases |
|---------|-----------|-------|-----------|
| **architect** | System design | File system, Bash | Architecture planning |
| **frontend** | User experience | File system, Bash | UI development |
| **backend** | Server systems | File system, Bash, AWS | API development |
| **security** | Security analysis | File system, Bash | Security reviews |
| **analyzer** | Problem solving | All tools | Debugging |
| **qa** | Quality assurance | File system, Bash | Testing |
| **performance** | Optimization | File system, Bash | Performance tuning |
| **refactorer** | Code quality | File system, Bash | Code improvement |
| **mentor** | Knowledge sharing | File system | Documentation |

## 🛠️ Configuration Options

### Thinking Depth Control
```bash
$ q chat
Amazon Q> /analyze --think

# Deeper analysis  
Amazon Q> /design --think-hard

# Maximum depth
Amazon Q> /troubleshoot --ultrathink
```

### Introspection Mode
```bash
$ q chat
Amazon Q> /analyze --introspect

# Debug SuperQ behavior
Amazon Q> /troubleshoot --introspect

# Optimize framework performance
Amazon Q> /improve --introspect --persona-performance
```

### Token Management
```bash
$ q chat
# Standard mode
Amazon Q> /build --react

# With compression
Amazon Q> /analyze --architecture
Amazon Q> /compact

# Native tools only
Amazon Q> /scan --security --no-tools
```

### Evidence-Based Development
SuperQ encourages:
- Documentation for design decisions
- Testing for quality improvements
- Metrics for performance work
- Security validation for deployments
- Analysis for architectural choices

## 📋 Command Categories

### Development (3 Commands)
- `/build` - Project builder with stack templates
- `/dev-setup` - Development environment setup
- `/test` - Testing framework

### Analysis & Improvement (5 Commands)
- `/review` - AI-powered code review with evidence-based recommendations
- `/analyze` - Code and system analysis
- `/troubleshoot` - Debugging and issue resolution
- `/improve` - Enhancement and optimization
- `/explain` - Documentation and explanations

### Operations (6 Commands)
- `/deploy` - Application deployment
- `/migrate` - Database and code migrations
- `/scan` - Security and validation
- `/estimate` - Project estimation
- `/cleanup` - Project maintenance
- `/git` - Git workflow management

### Design & Workflow (5 Commands)
- `/design` - System architecture
- `/spawn` - Parallel task execution
- `/document` - Documentation creation
- `/load` - Project context loading
- `/task` - Task management

## 🔧 Technical Architecture v2

SuperQ v2's architecture enables extensibility:

**🏗️ Modular Configuration**
- **Q.md** – Core configuration with @include references
- **.amazonq/shared/** – Centralized YAML templates
- **commands/shared/** – Reusable command patterns
- **@include System** – Template engine for configuration

**🎯 Unified Command System**
- **19 Commands** – Development lifecycle coverage
- **Command Inheritance** – Universal commands
- **Persona Integration** – 9 cognitive modes as context hooks
- **Template Validation** – Reference integrity checking

**📦 Architecture Benefits**
- **Single Source of Truth** – Centralized updates
- **Easy Extension** – Add new commands
- **Consistent Behavior** – Unified command handling
- **Reduced Duplication** – Template-based configuration

**✅ Quality Features**
- **Evidence-Based Approach** – Documentation encouraged
- **Research Integration** – Library documentation access
- **Error Recovery** – Graceful failure handling
- **Structured Output** – Organized file locations

## 📊 Comparison

| Aspect | Standard Amazon Q CLI | SuperQ Framework |
|--------|---------------------|----------------------|
| **Expertise** | General responses | 9 specialized personas |
| **Commands** | Manual instructions | 18 workflow commands |
| **Context** | Session-based | Git checkpoint support |
| **Tokens** | Standard usage | Compression options |
| **Approach** | General purpose | Evidence-based |
| **Documentation** | As needed | Systematic approach |
| **Quality** | Variable | Validation patterns |
| **Integration** | Basic tools | Advanced tool orchestration |

## 🔮 Use Cases

**Development Teams**
- Consistent approaches across domains
- Standardized workflows
- Evidence-based decisions
- Documentation practices

**Technical Leaders**
- Architecture reviews
- Performance optimization
- Code quality improvement
- Team knowledge sharing

**Operations**
- Deployment procedures
- Debugging workflows
- Security management
- Maintenance tasks

## 🎯 Suitability

**Good fit for:**
- ✅ Teams wanting consistent AI assistance
- ✅ Projects needing specialized approaches
- ✅ Evidence-based development practices
- ✅ Token-conscious workflows
- ✅ Domain-specific expertise needs

**May not suit:**
- ❌ Purely manual workflows
- ❌ Minimal configuration preferences
- ❌ Ad-hoc development styles
- ❌ Single-domain focus

## 🚦 Getting Started

1. **Install SuperQ**
   ```bash
   $ git clone https://github.com/NomenAK/SuperQ.git && cd SuperQ && ./install.sh
   ```

2. **Validate Installation**
   ```bash
   $ q chat
   Amazon Q> /load                                    # Load project context
   Amazon Q> /analyze --code --think                  # Test analysis
   Amazon Q> /context hooks add persona-architect
   Amazon Q> /analyze --architecture                  # Try personas
   ```

3. **Example Workflow**
   ```bash
   $ q chat
   Amazon Q> /design --api --ddd                      # Architecture design
   Amazon Q> /build --feature --tdd                   # Implementation
   Amazon Q> /test --coverage --e2e                   # Quality assurance
   Amazon Q> /deploy --env staging --plan             # Deployment
   ```

4. **Conversation Management**
   ```bash
   # Automatic resume of previous session
   $ q chat --resume
   
   # Manual save/load within chat
   Amazon Q> /save my-project-design
   Amazon Q> /load my-project-design
   ```

5. **Model Selection**
   ```bash
   # Change model in-session
   Amazon Q> /model

   # Launch with specific model
   $ q chat --model claude-3-opus-20240229
   
   # Set default model
   $ q settings chat.defaultModel claude-3-opus-20240229
   ```

6. **Tool Permissions**
   ```bash
   # Trust specific tools
   Amazon Q> /tools trust fs_read
   Amazon Q> /tools trust fs_write
   
   # Trust all tools
   Amazon Q> /tools trustall
   
   # Revoke trust
   Amazon Q> /tools untrust execute_bash
   ```

## 🛟 Support

- **Installation Help**: Run `./install.sh --help`
- **Command Details**: Check `~/.amazonq/commands/`
- **Settings Management**: Run `q settings all -f json-pretty`
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issues**: [GitHub Issues](https://github.com/NomenAK/SuperQ/issues)

## 🤝 Community

SuperQ welcomes contributions:
- **New Personas** for specialized workflows
- **Commands** for domain-specific operations  
- **Patterns** for development practices
- **Integrations** for productivity tools

Join the community: [Discussions](https://github.com/NomenAK/SuperQ/discussions)

## 📈 Version 2.0.1 Changes

**🎯 Architecture Improvements:**
- **Configuration Management**: @include reference system
- **Token Efficiency**: Compression options maintained
- **Command System**: Unified command inheritance
- **Persona System**: Now available as context hooks
- **Installer**: Enhanced with new modes
- **Maintenance**: Centralized configuration

**📊 Framework Details:**
- **Commands**: 19 specialized commands
- **Personas**: 9 cognitive approaches
- **Tool Integration**: File system, Bash, AWS
- **Methodology**: Evidence-based approach
- **Usage**: By development teams

## 🎉 Enhance Your Development

SuperQ provides a structured approach to using Amazon Q CLI with specialized commands, personas, and development patterns.

---

*SuperQ v2.0.1 – Development framework for Amazon Q CLI*

[⭐ Star on GitHub](https://github.com/NomenAK/SuperQ) | [💬 Discussions](https://github.com/NomenAK/SuperQ/discussions) | [🐛 Report Issues](https://github.com/NomenAK/SuperQ/issues)