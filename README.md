# Claude + Ollama Development Setup

A complete project for running Claude Code with local Ollama models, providing a free and private AI coding assistant.

## 🚀 Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd claude-ollama-dev

# Start Ollama (choose your mode)
make start          # CPU mode (default)
# OR
make start-gpu      # GPU mode (requires NVIDIA setup)

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
- Optional: Ollama Desktop App (released July 2025) for GUI experience

## 🆕 What's New in 2025

**Ollama Desktop App**: Native GUI application for macOS and Windows with drag-and-drop support for PDFs and images, context-length slider (up to 128K tokens), and multimodal capabilities.

**Enhanced Multimodal Support**: New engine supporting vision models like Llama 4 Scout and Gemma 3 with improved accuracy and memory management.

**Structured Outputs**: JSON Schema support for type-safe API responses and streaming responses with tool calls.

**Open WebUI Integration**: Optional web interface for better user experience (included in this setup).

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

Choose your deployment mode based on your hardware:

```bash
# CPU-only mode (default)
make start
# Or manually: docker-compose up -d

# GPU-accelerated mode (requires NVIDIA GPU + Container Toolkit)
make start-gpu
# Or manually: docker-compose --profile gpu up -d

# Explicit CPU mode
make start-cpu
# Or manually: docker-compose --profile cpu up -d
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
make start          # Start Ollama container (CPU mode)
make start-gpu      # Start Ollama container (GPU mode)
make start-cpu      # Start Ollama container (explicit CPU mode)
make start-webui    # Start with Open WebUI interface
make stop           # Stop Ollama container
make restart        # Restart Ollama container
make logs           # View Ollama logs
make status         # Check container status
make health         # Check service health
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

### Ollama Desktop App (New 2025)

**Download and Install:**
- macOS 12+ and Windows native app available
- Download from: https://ollama.com/download
- Features: Drag-and-drop PDFs/images, context slider (128K tokens), chat history

### VSCode with Continue

1. Install the "Continue" extension from VSCode marketplace
2. Use the provided config:

```bash
# Copy Continue config
cp ide-configs/vscode-continue.json ~/.continue/config.json
```

3. Press `Cmd+Shift+P` → "Continue: Open Config" to verify

### Open WebUI (Web Interface)

1. Start with WebUI profile:
```bash
docker-compose --profile webui --profile cpu up -d
```

2. Access at http://localhost:3000
3. Features: Chat interface, model switching, file uploads, conversation history

### JetBrains IDEs with Tabby

1. Install the "Tabby" plugin from Settings → Plugins → Marketplace
2. In Settings → Tools → Tabby, set endpoint to `http://localhost:11434`
3. Use the provided config as reference:

```bash
# View Tabby config reference
cat ide-configs/jetbrains-tabby.json
```

## 🤖 Model Recommendations

| Model | Size | Use Case | Speed | Multimodal |
|-------|------|----------|-------|------------|
| `qwen3-coder` | Large | Complex refactoring, full projects | Medium | ❌ |
| `deepseek-coder:6.7b` | Small | Quick questions, autocomplete | Fast | ❌ |
| `codellama:13b` | Medium | General coding tasks | Medium | ❌ |
| `llama4-scout` | Large | Vision + coding tasks | Medium | ✅ |
| `gemma3` | Medium | Multimodal reasoning | Medium | ✅ |
| `gpt-oss:20b` | Large | Advanced coding challenges | Slow | ❌ |

**New 2025 Models with Enhanced Capabilities:**
- **Vision Models**: Support for image analysis and document processing
- **Structured Outputs**: JSON Schema validation for API responses
- **Extended Context**: Up to 128K tokens for large document processing

## 🚀 Performance Tips

### GPU Acceleration

This setup supports both CPU and GPU modes using Docker Compose profiles:

**Prerequisites for GPU mode:**
- NVIDIA GPU with CUDA support
- NVIDIA Container Toolkit installed
- Docker configured with NVIDIA runtime

**GPU Mode Usage:**
```bash
# Start with GPU acceleration
docker-compose --profile gpu up -d

# Or using Makefile
make start-gpu

# Verify GPU access
docker exec ollama nvidia-smi
```

**CPU Mode Usage:**
```bash
# Default CPU mode
docker-compose up -d

# Explicit CPU mode
docker-compose --profile cpu up -d

# Or using Makefile
make start-cpu
```

**Web UI Mode (Optional):**
```bash
# Start with Open WebUI for better interface
docker-compose --profile webui --profile cpu up -d
# Or for GPU: docker-compose --profile webui --profile gpu up -d

# Access at http://localhost:3000
```

**Profile Configuration:**
- `cpu` profile: CPU-only execution (default)
- `gpu` profile: NVIDIA GPU acceleration with modern Docker Compose v3.8 syntax
- `webui` profile: Open WebUI interface for enhanced user experience
- All profiles include health checks and can be combined

### Windows GPU Setup

If you're on Windows with an NVIDIA GPU, follow these steps to enable GPU acceleration:

**Step 1: Install Prerequisites**
```powershell
# Install Docker Desktop for Windows
# Download from: https://www.docker.com/products/docker-desktop/

# Ensure WSL2 is enabled and updated
wsl --update
wsl --set-default-version 2
```

**Step 2: Install NVIDIA Container Toolkit**
```powershell
# Install NVIDIA Container Toolkit for Windows
# Download from: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker

# Or use winget (Windows Package Manager)
winget install NVIDIA.ContainerToolkit
```

**Step 3: Configure Docker Desktop**
1. Open Docker Desktop
2. Go to Settings → General
3. Ensure "Use WSL 2 based engine" is checked
4. Go to Settings → Resources → WSL Integration
5. Enable integration with your WSL2 distro

**Step 4: Verify GPU Access**
```bash
# In WSL2 terminal, test GPU access
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Should show your GPU information
```

**Step 5: Start with GPU Profile**
```bash
# In your WSL2 terminal (in project directory)
docker-compose --profile gpu up -d

# Verify Ollama can access GPU
docker exec ollama nvidia-smi
```

**Windows-Specific Notes:**
- GPU support requires WSL2 backend in Docker Desktop
- NVIDIA drivers must be installed on Windows host (not in WSL2)
- Container Toolkit handles GPU passthrough to WSL2 containers
- Performance may vary compared to native Linux installations

**Troubleshooting Windows GPU:**
```bash
# Check if GPU is visible in WSL2
nvidia-smi

# Verify Docker can see GPU
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Check Docker Desktop WSL2 integration
docker context ls
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
   
   # Restart if needed (maintain same profile)
   make restart
   
   # Or restart with specific profile
   docker-compose --profile gpu restart  # For GPU mode
   docker-compose --profile cpu restart  # For CPU mode
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
