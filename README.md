# Claude + Ollama Development Setup

A complete project for running Claude Code with local Ollama models, providing a free and private AI coding assistant.

## 🚀 Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd claude-ollama-dev

# Start Ollama
make start

# Pull a coding model
make pull-model MODEL=qwen3-coder

# Setup environment
make setup-env

# Start coding with Claude Code
make claude MODEL=qwen3-coder
```

## 📋 Prerequisites

- Docker and Docker Compose
- Claude Code CLI (installed automatically)
- 8GB+ RAM recommended (16GB+ for larger models)
- Optional: NVIDIA GPU for acceleration

## 🏗️ Project Structure

```
claude-ollama-dev/
├── docker-compose.yml          # Ollama container configuration
├── Makefile                    # Convenient commands
├── README.md                   # This file
├── scripts/                    # Utility scripts
│   ├── setup.sh               # Initial setup
│   ├── start-ollama.sh        # Start Ollama with Claude Code
│   ├── model-manager.sh       # Model management utilities
│   └── health-check.sh        # System health checks
├── ide-configs/                # IDE integration configs
│   ├── vscode-continue.json   # Continue extension config
│   └── jetbrains-tabby.json   # Tabby plugin config
└── docs/                      # Documentation
    ├── troubleshooting.md     # Common issues
    └── model-guide.md         # Model recommendations
```

## 🛠️ Installation & Setup

### Step 1: Start Ollama

```bash
# Using Makefile (recommended)
make start

# Or manually
docker-compose up -d
```

### Step 2: Pull a Coding Model

```bash
# Recommended model for coding
make pull-model MODEL=qwen3-coder

# Alternative models
make pull-model MODEL=deepseek-coder:6.7b  # Lightweight, fast
make pull-model MODEL=codellama:13b        # Classic choice
make pull-model MODEL=gpt-oss:20b          # Strong coding model
```

### Step 3: Install Claude Code

```bash
# Install Claude Code CLI
make install-claude

# Or manually:
# macOS / Linux / WSL:
curl -fsSL https://claude.ai/install.sh | bash

# Windows (PowerShell):
irm https://claude.ai/install.ps1 | iex
```

### Step 4: Configure Environment

```bash
# Set environment variables
make setup-env

# Or manually:
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
```

### Step 5: Start Coding

```bash
# Start Claude Code with a model
make claude MODEL=qwen3-coder

# Or manually:
claude --model qwen3-coder
```

## 🎯 Available Commands

### Ollama Management
```bash
make start          # Start Ollama container
make stop           # Stop Ollama container
make restart        # Restart Ollama container
make logs           # View Ollama logs
make status         # Check container status
```

### Model Management
```bash
make pull-model MODEL=<model-name>    # Download a model
make list-models                     # Show downloaded models
make remove-model MODEL=<model-name>  # Remove a model
make model-info MODEL=<model-name>    # Show model details
```

### Claude Code
```bash
make claude MODEL=<model-name>        # Start Claude Code
make install-claude                   # Install Claude Code CLI
make setup-env                        # Setup environment variables
make quick-start MODEL=<model-name>   # Full quick start
```

### Utilities
```bash
make health-check                     # System health check
make clean                            # Clean up Docker resources
make help                             # Show all available commands
```

## 🔧 IDE Integration

### VSCode with Continue

1. Install the "Continue" extension from VSCode marketplace
2. Use the provided config:

```bash
# Copy Continue config
cp ide-configs/vscode-continue.json ~/.continue/config.json
```

3. Press `Cmd+Shift+P` → "Continue: Open Config" to verify

### JetBrains IDEs with Tabby

1. Install the "Tabby" plugin from Settings → Plugins → Marketplace
2. In Settings → Tools → Tabby, set endpoint to `http://localhost:11434`
3. Use the provided config as reference:

```bash
# View Tabby config reference
cat ide-configs/jetbrains-tabby.json
```

## 🤖 Model Recommendations

| Model | Size | Use Case | Speed |
|-------|------|----------|-------|
| `qwen3-coder` | Large | Complex refactoring, full projects | Medium |
| `deepseek-coder:6.7b` | Small | Quick questions, autocomplete | Fast |
| `codellama:13b` | Medium | General coding tasks | Medium |
| `gpt-oss:20b` | Large | Advanced coding challenges | Slow |

## 🚀 Performance Tips

### GPU Acceleration
Uncomment the GPU section in `docker-compose.yml` if you have an NVIDIA GPU:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

### Resource Management
```bash
# Monitor resource usage
docker stats ollama

# Check system health
make health-check

# List models and sizes
make list-models
```

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```bash
   # Check environment variables
   echo $ANTHROPIC_AUTH_TOKEN
   echo $ANTHROPIC_BASE_URL
   
   # Reset environment
   make setup-env
   ```

2. **Connection Failed**
   ```bash
   # Check if Ollama is running
   make status
   
   # Restart if needed
   make restart
   ```

3. **Model Not Found**
   ```bash
   # List available models
   make list-models
   
   # Pull the model
   make pull-model MODEL=<model-name>
   ```

4. **Slow Responses**
   - Try a smaller model (`deepseek-coder:6.7b`)
   - Enable GPU support
   - Check system resources with `make health-check`

For detailed troubleshooting, see `docs/troubleshooting.md`.

## 📚 Advanced Usage

### Custom Startup Script

Create a personal startup script:

```bash
#!/bin/bash
cd ~/ollama-dev
docker-compose up -d
echo "Waiting for Ollama to be ready..."
sleep 3
cd -
claude --model qwen3-coder
```

Save as `~/bin/aicode`, make executable: `chmod +x ~/bin/aicode`

### Environment Persistence

Add to your shell profile (~/.zshrc, ~/.bashrc):

```bash
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
```

### Model Switching

Switch models based on task complexity:

```bash
# Complex tasks
claude --model qwen3-coder "Refactor this entire module"

# Quick questions  
claude --model deepseek-coder:6.7b "What does this function do?"
```

## 🧹 Maintenance

### Regular Cleanup
```bash
# Remove unused Docker resources
make clean

# Remove unused models
docker exec ollama ollama rm <unused-model>

# Check disk usage
docker system df
```

### Updates
```bash
# Update Ollama image
docker-compose pull

# Restart with new image
make restart
```

## 📄 License

This project is provided as-is for educational and development purposes.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai/) for the local AI runtime
- [Anthropic](https://claude.ai/) for Claude Code
- The open-source AI community for the amazing models
