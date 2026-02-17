#!/bin/bash

# Start Ollama and Claude Code together
# This script starts Ollama and launches Claude Code with a specified model

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_MODEL="qwen3-coder"
OLLAMA_PORT=11434
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

check_ollama_running() {
    if curl -s "$BASE_URL/api/version" >/dev/null 2>&1; then
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
        if check_ollama_running; then
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

start_ollama_if_needed() {
    if check_ollama_running; then
        print_success "Ollama is already running"
        return 0
    fi
    
    print_status "Starting Ollama container..."
    docker-compose up -d
    
    if wait_for_ollama; then
        return 0
    else
        print_error "Failed to start Ollama"
        return 1
    fi
}

check_model_available() {
    local model="$1"
    if docker exec ollama ollama list | grep -q "$model"; then
        return 0
    else
        return 1
    fi
}

pull_model_if_needed() {
    local model="$1"
    
    if check_model_available "$model"; then
        print_success "Model $model is already available"
        return 0
    fi
    
    print_status "Pulling model $model..."
    if docker exec ollama ollama pull "$model"; then
        print_success "Model $model downloaded successfully"
        return 0
    else
        print_error "Failed to pull model $model"
        return 1
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS] [MODEL]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -l, --list     List available models"
    echo "  -s, --status   Show Ollama status"
    echo ""
    echo "Models:"
    echo "  qwen3-coder           (default) - Large context, strong code understanding"
    echo "  deepseek-coder:6.7b   - Lightweight, fast on CPU"
    echo "  codellama:13b         - Classic coding model"
    echo "  gpt-oss:20b           - Advanced coding challenges"
    echo ""
    echo "Examples:"
    echo "  $0                    # Start with default model"
    echo "  $0 qwen3-coder       # Start with specific model"
    echo "  $0 --list            # List available models"
}

list_models() {
    print_status "Available models:"
    docker exec ollama ollama list 2>/dev/null || {
        print_error "Could not list models. Is Ollama running?"
        exit 1
    }
}

show_status() {
    print_status "Ollama Status:"
    echo "Container: $(docker ps --filter name=ollama --format '{{.Status}}' 2>/dev/null || echo 'Not running')"
    echo "API: $(check_ollama_running && echo 'Responding' || echo 'Not responding')"
    echo "Port: $OLLAMA_PORT"
    echo ""
    
    if check_ollama_running; then
        list_models
    fi
}

# Main execution
main() {
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    # Parse command line arguments
    MODEL="$DEFAULT_MODEL"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                list_models
                exit 0
                ;;
            -s|--status)
                show_status
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                MODEL="$1"
                shift
                ;;
        esac
        shift
    done
    
    # Check if Claude Code is installed
    if ! command -v claude >/dev/null 2>&1; then
        print_error "Claude Code is not installed"
        print_status "Install it with: curl -fsSL https://claude.ai/install.sh | bash"
        exit 1
    fi
    
    # Start Ollama if needed
    if ! start_ollama_if_needed; then
        exit 1
    fi
    
    # Pull model if needed
    if ! pull_model_if_needed "$MODEL"; then
        exit 1
    fi
    
    # Set environment variables
    export ANTHROPIC_AUTH_TOKEN="ollama"
    export ANTHROPIC_BASE_URL="$BASE_URL"
    
    # Start Claude Code
    print_status "Starting Claude Code with model: $MODEL"
    print_success "Ready to code! 🚀"
    echo ""
    
    exec claude --model "$MODEL"
}

# Run main function
main "$@"
