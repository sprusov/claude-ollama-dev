#!/bin/bash

# Claude + Ollama Setup Script
# Automated setup for local AI development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLLAMA_PORT=11434
DEFAULT_MODEL="qwen3-coder"
AUTH_TOKEN="ollama"
BASE_URL="http://localhost:$OLLAMA_PORT"

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

wait_for_ollama() {
    print_status "Waiting for Ollama to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$BASE_URL/api/version" >/dev/null 2>&1; then
            print_success "Ollama is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 1
        ((attempt++))
    done
    
    print_error "Ollama failed to start within $max_attempts seconds"
    return 1
}

# Main setup process
main() {
    print_status "Starting Claude + Ollama setup..."
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! check_command "docker"; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! check_command "docker-compose"; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
    
    # Start Ollama
    print_status "Starting Ollama container..."
    if docker-compose ps | grep -q "Up"; then
        print_warning "Ollama is already running"
    else
        docker-compose up -d
        print_success "Ollama container started"
    fi
    
    # Wait for Ollama to be ready
    wait_for_ollama
    
    # Install Claude Code
    print_status "Installing Claude Code CLI..."
    if check_command "claude"; then
        print_warning "Claude Code is already installed"
        claude --version 2>/dev/null || echo "Version: unknown"
    else
        print_status "Downloading Claude Code installer..."
        if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "msys" ]]; then
            curl -fsSL https://claude.ai/install.sh | bash
            print_success "Claude Code installed successfully"
        else
            print_error "Unsupported operating system for automatic installation"
            print_status "Please install Claude Code manually from https://claude.ai/install"
            exit 1
        fi
    fi
    
    # Pull default model
    print_status "Pulling default model ($DEFAULT_MODEL)..."
    if docker exec ollama ollama list | grep -q "$DEFAULT_MODEL"; then
        print_warning "Model $DEFAULT_MODEL is already downloaded"
    else
        docker exec ollama ollama pull "$DEFAULT_MODEL"
        print_success "Model $DEFAULT_MODEL downloaded successfully"
    fi
    
    # Setup environment variables
    print_status "Setting up environment variables..."
    
    # Create shell profile additions
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SHELL_RC="$HOME/.bash_profile"
        fi
    fi
    
    if [ -n "$SHELL_RC" ]; then
        if ! grep -q "ANTHROPIC_AUTH_TOKEN" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# Claude + Ollama environment variables" >> "$SHELL_RC"
            echo "export ANTHROPIC_AUTH_TOKEN=$AUTH_TOKEN" >> "$SHELL_RC"
            echo "export ANTHROPIC_BASE_URL=$BASE_URL" >> "$SHELL_RC"
            print_success "Environment variables added to $SHELL_RC"
        else
            print_warning "Environment variables already exist in $SHELL_RC"
        fi
    fi
    
    # Set environment variables for current session
    export ANTHROPIC_AUTH_TOKEN="$AUTH_TOKEN"
    export ANTHROPIC_BASE_URL="$BASE_URL"
    
    # Verify setup
    print_status "Verifying setup..."
    
    # Check Claude Code can connect
    if claude --version >/dev/null 2>&1; then
        print_success "Claude Code is working"
    else
        print_error "Claude Code verification failed"
        exit 1
    fi
    
    # Show available models
    print_status "Available models:"
    docker exec ollama ollama list
    
    # Final instructions
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Restart your terminal or run: source $SHELL_RC"
    echo "2. Start coding with: claude --model $DEFAULT_MODEL"
    echo "3. Or use the Makefile: make claude MODEL=$DEFAULT_MODEL"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "- View all commands: make help"
    echo "- Check system health: make health-check"
    echo "- List models: make list-models"
    echo "- Pull new models: make pull-model MODEL=<model-name>"
    echo ""
    print_success "Happy coding with your local AI assistant!"
}

# Run main function
main "$@"
