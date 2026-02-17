#!/bin/bash

# Model Management Script
# Utilities for managing Ollama models

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="ollama"

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

check_container_running() {
    docker ps --filter name="$CONTAINER_NAME" --quiet | grep -q . 2>/dev/null
}

format_size() {
    local size="$1"
    if [[ $size -gt 1073741824 ]]; then
        echo "$(( size / 1073741824 ))GB"
    elif [[ $size -gt 1048576 ]]; then
        echo "$(( size / 1048576 ))MB"
    elif [[ $size -gt 1024 ]]; then
        echo "$(( size / 1024 ))KB"
    else
        echo "${size}B"
    fi
}

show_usage() {
    echo "Model Management Utility for Ollama"
    echo ""
    echo "Usage: $0 COMMAND [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list                    List all downloaded models"
    echo "  pull MODEL              Download a model"
    echo "  remove MODEL            Remove a model"
    echo "  info MODEL              Show model details"
    echo "  search QUERY            Search available models"
    echo "  cleanup                 Remove unused models"
    echo "  stats                   Show model statistics"
    echo "  recommend               Show recommended models"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 pull qwen3-coder"
    echo "  $0 info qwen3-coder"
    echo "  $0 search coder"
    echo "  $0 cleanup"
}

list_models() {
    print_status "Downloaded models:"
    
    if ! check_container_running; then
        print_error "Ollama container is not running"
        return 1
    fi
    
    local output
    output=$(docker exec "$CONTAINER_NAME" ollama list 2>/dev/null)
    
    if [ -z "$output" ] || [[ "$output" == *"no models"* ]]; then
        print_warning "No models downloaded"
        return 0
    fi
    
    echo "$output" | while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*NAME[[:space:]]* ]]; then
            echo -e "${BLUE}$line${NC}"
        elif [[ "$line" =~ ^[[:space:]]*[^[:space:]] ]]; then
            echo -e "${GREEN}$line${NC}"
        fi
    done
}

pull_model() {
    local model="$1"
    
    if [ -z "$model" ]; then
        print_error "Model name required"
        echo "Usage: $0 pull MODEL"
        return 1
    fi
    
    if ! check_container_running; then
        print_error "Ollama container is not running"
        return 1
    fi
    
    print_status "Pulling model: $model"
    
    if docker exec "$CONTAINER_NAME" ollama pull "$model"; then
        print_success "Model $model downloaded successfully"
        
        # Show model info
        echo ""
        print_status "Model information:"
        docker exec "$CONTAINER_NAME" ollama show "$model" 2>/dev/null | head -10
    else
        print_error "Failed to pull model $model"
        return 1
    fi
}

remove_model() {
    local model="$1"
    
    if [ -z "$model" ]; then
        print_error "Model name required"
        echo "Usage: $0 remove MODEL"
        return 1
    fi
    
    if ! check_container_running; then
        print_error "Ollama container is not running"
        return 1
    fi
    
    # Check if model exists
    if ! docker exec "$CONTAINER_NAME" ollama list | grep -q "$model"; then
        print_warning "Model $model not found"
        return 0
    fi
    
    print_status "Removing model: $model"
    
    if docker exec "$CONTAINER_NAME" ollama rm "$model"; then
        print_success "Model $model removed successfully"
    else
        print_error "Failed to remove model $model"
        return 1
    fi
}

show_model_info() {
    local model="$1"
    
    if [ -z "$model" ]; then
        print_error "Model name required"
        echo "Usage: $0 info MODEL"
        return 1
    fi
    
    if ! check_container_running; then
        print_error "Ollama container is not running"
        return 1
    fi
    
    # Check if model exists
    if ! docker exec "$CONTAINER_NAME" ollama list | grep -q "$model"; then
        print_error "Model $model not found"
        return 1
    fi
    
    print_status "Model information for: $model"
    docker exec "$CONTAINER_NAME" ollama show "$model"
}

search_models() {
    local query="$1"
    
    if [ -z "$query" ]; then
        print_error "Search query required"
        echo "Usage: $0 search QUERY"
        return 1
    fi
    
    print_status "Searching for models matching: $query"
    echo ""
    
    # Recommended models based on search
    case "$query" in
        *coder*|*code*)
            echo -e "${GREEN}Recommended coding models:${NC}"
            echo "  qwen3-coder          - Large context, strong code understanding"
            echo "  deepseek-coder:6.7b  - Lightweight, fast on CPU"
            echo "  codellama:13b        - Classic coding model"
            echo "  gpt-oss:20b          - Advanced coding challenges"
            ;;
        *small*|*fast*|*light*)
            echo -e "${GREEN}Recommended lightweight models:${NC}"
            echo "  deepseek-coder:6.7b  - Fast coding assistant"
            echo "  phi3:mini           - Small general model"
            echo "  gemma:2b            - Lightweight general model"
            ;;
        *large*|*big*|*powerful*)
            echo -e "${GREEN}Recommended large models:${NC}"
            echo "  qwen3-coder          - Large context coding model"
            echo "  gpt-oss:20b          - Advanced coding model"
            echo "  llama3:70b           - Large general model"
            ;;
        *)
            echo -e "${GREEN}Popular models:${NC}"
            echo "  qwen3-coder          - Coding focused"
            echo "  llama3:8b            - General purpose"
            echo "  mistral:7b           - Balanced performance"
            echo "  deepseek-coder:6.7b  - Lightweight coding"
            ;;
    esac
    
    echo ""
    print_status "Pull a model with: $0 pull MODEL_NAME"
}

cleanup_models() {
    print_status "Cleaning up unused models..."
    
    if ! check_container_running; then
        print_error "Ollama container is not running"
        return 1
    fi
    
    local models
    models=$(docker exec "$CONTAINER_NAME" ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
    
    if [ -z "$models" ]; then
        print_warning "No models to clean up"
        return 0
    fi
    
    echo "Available models:"
    echo "$models" | nl
    
    echo ""
    read -p "Enter model numbers to remove (space-separated, or 'all'): " selection
    
    if [ "$selection" = "all" ]; then
        echo "$models" | while read -r model; do
            if [ -n "$model" ]; then
                print_status "Removing: $model"
                docker exec "$CONTAINER_NAME" ollama rm "$model" 2>/dev/null || true
            fi
        done
        print_success "All models removed"
    else
        for num in $selection; do
            local model
            model=$(echo "$models" | sed -n "${num}p")
            if [ -n "$model" ]; then
                print_status "Removing: $model"
                docker exec "$CONTAINER_NAME" ollama rm "$model" 2>/dev/null || print_warning "Failed to remove $model"
            fi
        done
        print_success "Selected models removed"
    fi
}

show_stats() {
    print_status "Model Statistics:"
    
    if ! check_container_running; then
        print_error "Ollama container is not running"
        return 1
    fi
    
    # Get container stats
    local container_size
    container_size=$(docker ps --filter name="$CONTAINER_NAME" --format "{{.Size}}" 2>/dev/null || echo "Unknown")
    
    echo "Container Size: $container_size"
    echo ""
    
    # Get model info
    local models
    models=$(docker exec "$CONTAINER_NAME" ollama list 2>/dev/null | tail -n +2)
    
    if [ -z "$models" ]; then
        print_warning "No models downloaded"
        return 0
    fi
    
    echo "Downloaded Models:"
    echo "$models" | while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[^[:space:]] ]]; then
            local model_name size
            model_name=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $2}')
            echo "  $model_name: $size"
        fi
    done
    
    # Docker volume info
    echo ""
    local volume_size
    volume_size=$(docker system df --format "{{.Size}}" --filter volume=ollama_data 2>/dev/null || echo "Unknown")
    echo "Ollama Data Volume: $volume_size"
}

show_recommendations() {
    print_status "Model Recommendations:"
    echo ""
    
    echo -e "${GREEN}For Coding Tasks:${NC}"
    echo "  qwen3-coder          - Best overall, large context window"
    echo "  deepseek-coder:6.7b  - Fast, good for quick tasks"
    echo "  codellama:13b        - Reliable, well-tested"
    echo ""
    
    echo -e "${GREEN}For General Chat:${NC}"
    echo "  llama3:8b            - Balanced performance"
    echo "  mistral:7b           - Fast and capable"
    echo "  phi3:mini           - Lightweight conversations"
    echo ""
    
    echo -e "${GREEN}Hardware Recommendations:${NC}"
    echo "  8GB RAM:            deepseek-coder:6.7b, phi3:mini"
    echo "  16GB RAM:           qwen3-coder, llama3:8b, codellama:13b"
    echo "  32GB+ RAM:          gpt-oss:20b, llama3:70b"
    echo ""
    
    echo -e "${GREEN}GPU Support:${NC}"
    echo "  Enable GPU in docker-compose.yml for 10x+ speed improvement"
    echo "  NVIDIA GPU with CUDA 11.0+ recommended"
}

# Main execution
main() {
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    case "$1" in
        list)
            list_models
            ;;
        pull)
            pull_model "$2"
            ;;
        remove)
            remove_model "$2"
            ;;
        info)
            show_model_info "$2"
            ;;
        search)
            search_models "$2"
            ;;
        cleanup)
            cleanup_models
            ;;
        stats)
            show_stats
            ;;
        recommend)
            show_recommendations
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
