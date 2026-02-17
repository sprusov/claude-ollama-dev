#!/bin/bash

# Health Check Script
# Comprehensive system health monitoring for Claude + Ollama setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLLAMA_PORT=11434
BASE_URL="http://localhost:$OLLAMA_PORT"
CONTAINER_NAME="ollama"

# Health check thresholds
WARNING_MEMORY_PERCENT=80
CRITICAL_MEMORY_PERCENT=90
WARNING_DISK_PERCENT=80
CRITICAL_DISK_PERCENT=90

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

get_memory_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local total_mem
        local used_mem
        total_mem=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
        used_mem=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//' | awk '{print $1 * 4096 / 1024 / 1024 / 1024}')
        echo "${used_mem} ${total_mem}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        awk '/^MemTotal:|^MemAvailable:/ {print $2/1024/1024}' /proc/meminfo | tr '\n' ' '
    else
        echo "0 0"
    fi
}

get_disk_usage() {
    df . | tail -1 | awk '{print $3, $2}'
}

check_docker() {
    print_header "Docker Environment"
    
    local docker_status=0
    
    # Check Docker daemon
    if check_command "docker"; then
        if docker info >/dev/null 2>&1; then
            print_success "Docker daemon is running"
            docker --version
        else
            print_error "Docker daemon is not accessible"
            docker_status=1
        fi
    else
        print_error "Docker is not installed"
        docker_status=1
    fi
    
    # Check Docker Compose
    if check_command "docker-compose"; then
        print_success "Docker Compose is installed"
        docker-compose --version
    else
        print_error "Docker Compose is not installed"
        docker_status=1
    fi
    
    return $docker_status
}

check_container() {
    print_header "Ollama Container"
    
    local container_status=0
    
    # Check if container exists
    if docker ps -a --filter name="$CONTAINER_NAME" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        # Check if container is running
        if docker ps --filter name="$CONTAINER_NAME" --format "{{.Status}}" | grep -q "Up"; then
            print_success "Ollama container is running"
            
            # Show container details
            local uptime
            uptime=$(docker ps --filter name="$CONTAINER_NAME" --format "{{.Status}}")
            echo "  Uptime: $uptime"
            
            # Show resource usage
            if docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$CONTAINER_NAME" >/dev/null 2>&1; then
                echo "  Resource Usage:"
                docker stats --no-stream --format "    CPU: {{.CPUPerc}}, Memory: {{.MemUsage}}" "$CONTAINER_NAME"
            fi
        else
            print_error "Ollama container exists but is not running"
            echo "  Status: $(docker ps -a --filter name="$CONTAINER_NAME" --format "{{.Status}}")"
            container_status=1
        fi
    else
        print_error "Ollama container not found"
        container_status=1
    fi
    
    return $container_status
}

check_api() {
    print_header "Ollama API"
    
    local api_status=0
    
    # Check API connectivity
    if curl -s --max-time 5 "$BASE_URL/api/version" >/dev/null 2>&1; then
        print_success "Ollama API is responding"
        
        # Get API version
        local version
        version=$(curl -s "$BASE_URL/api/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
        echo "  API Version: $version"
        
        # Test API with a simple request
        if curl -s --max-time 10 "$BASE_URL/api/generate" -d '{"model":"test","prompt":"test","stream":false}' >/dev/null 2>&1; then
            print_success "API endpoint is functional"
        else
            print_warning "API endpoint test failed (may be normal if no models loaded)"
        fi
    else
        print_error "Ollama API is not responding"
        echo "  URL: $BASE_URL"
        api_status=1
    fi
    
    return $api_status
}

check_models() {
    print_header "Models"
    
    local model_status=0
    
    if docker exec "$CONTAINER_NAME" ollama list >/dev/null 2>&1; then
        local model_count
        model_count=$(docker exec "$CONTAINER_NAME" ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        
        if [ "$model_count" -gt 0 ]; then
            print_success "$model_count model(s) available"
            
            echo "  Available models:"
            docker exec "$CONTAINER_NAME" ollama list 2>/dev/null | tail -n +2 | head -5 | while IFS= read -r line; do
                echo "    $line"
            done
            
            if [ "$model_count" -gt 5 ]; then
                echo "    ... and $((model_count - 5)) more"
            fi
        else
            print_warning "No models downloaded"
            echo "  Pull a model with: docker exec $CONTAINER_NAME ollama pull <model>"
            model_status=1
        fi
    else
        print_error "Cannot list models (container may not be running)"
        model_status=1
    fi
    
    return $model_status
}

check_claude_code() {
    print_header "Claude Code"
    
    local claude_status=0
    
    if check_command "claude"; then
        print_success "Claude Code is installed"
        
        # Get version
        local version
        version=$(claude --version 2>/dev/null || echo "Unknown")
        echo "  Version: $version"
        
        # Check environment variables
        if [ -n "$ANTHROPIC_AUTH_TOKEN" ] && [ -n "$ANTHROPIC_BASE_URL" ]; then
            print_success "Environment variables are set"
            echo "  AUTH_TOKEN: $ANTHROPIC_AUTH_TOKEN"
            echo "  BASE_URL: $ANTHROPIC_BASE_URL"
        else
            print_warning "Environment variables not set"
            echo "  Run: export ANTHROPIC_AUTH_TOKEN=ollama"
            echo "  Run: export ANTHROPIC_BASE_URL=$BASE_URL"
            claude_status=1
        fi
    else
        print_error "Claude Code is not installed"
        echo "  Install with: curl -fsSL https://claude.ai/install.sh | bash"
        claude_status=1
    fi
    
    return $claude_status
}

check_system_resources() {
    print_header "System Resources"
    
    # Memory usage
    local mem_info
    mem_info=$(get_memory_usage)
    local used_mem=$(echo $mem_info | cut -d' ' -f1)
    local total_mem=$(echo $mem_info | cut -d' ' -f2)
    
    if [ "$total_mem" != "0" ]; then
        local mem_percent
        mem_percent=$(echo "scale=1; $used_mem * 100 / $total_mem" | bc 2>/dev/null || echo "0")
        
        echo "Memory: ${used_mem}GB / ${total_mem}GB (${mem_percent}%)"
        
        if (( $(echo "$mem_percent >= $CRITICAL_MEMORY_PERCENT" | bc -l 2>/dev/null || echo 0) )); then
            print_error "Memory usage is critically high"
        elif (( $(echo "$mem_percent >= $WARNING_MEMORY_PERCENT" | bc -l 2>/dev/null || echo 0) )); then
            print_warning "Memory usage is high"
        else
            print_success "Memory usage is normal"
        fi
    else
        print_warning "Could not determine memory usage"
    fi
    
    # Disk usage
    local disk_info
    disk_info=$(get_disk_usage)
    local used_disk=$(echo $disk_info | cut -d' ' -f1)
    local total_disk=$(echo $disk_info | cut -d' ' -f2)
    
    if [ "$total_disk" != "0" ]; then
        local disk_percent
        disk_percent=$(echo "scale=1; $used_disk * 100 / $total_disk" | bc 2>/dev/null || echo "0")
        local used_gb=$(echo "scale=1; $used_disk / 1024 / 1024" | bc 2>/dev/null || echo "0")
        local total_gb=$(echo "scale=1; $total_disk / 1024 / 1024" | bc 2>/dev/null || echo "0")
        
        echo "Disk: ${used_gb}GB / ${total_gb}GB (${disk_percent}%)"
        
        if (( $(echo "$disk_percent >= $CRITICAL_DISK_PERCENT" | bc -l 2>/dev/null || echo 0) )); then
            print_error "Disk usage is critically high"
        elif (( $(echo "$disk_percent >= $WARNING_DISK_PERCENT" | bc -l 2>/dev/null || echo 0) )); then
            print_warning "Disk usage is high"
        else
            print_success "Disk usage is normal"
        fi
    else
        print_warning "Could not determine disk usage"
    fi
    
    # Docker system info
    echo ""
    echo "Docker System:"
    if docker system df >/dev/null 2>&1; then
        docker system df --format "  {{.Type}}: {{.Count}} items, {{.Size}}" | head -3
    else
        print_warning "Could not get Docker system info"
    fi
}

check_network() {
    print_header "Network Connectivity"
    
    # Check if port is available
    if lsof -i ":$OLLAMA_PORT" >/dev/null 2>&1; then
        print_success "Port $OLLAMA_PORT is in use by Ollama"
    else
        print_warning "Port $OLLAMA_PORT is not in use"
    fi
    
    # Check localhost connectivity
    if curl -s --max-time 2 "http://localhost:$OLLAMA_PORT" >/dev/null 2>&1; then
        print_success "localhost connectivity working"
    else
        print_error "localhost connectivity failed"
    fi
}

generate_report() {
    print_header "Health Summary"
    
    local total_checks=0
    local passed_checks=0
    local failed_checks=0
    local warnings=0
    
    # This would be populated by the actual checks above
    # For now, just show a summary format
    echo "Overall System Health: NEEDS IMPLEMENTATION"
    echo ""
    echo "Recommendations:"
    echo "- Fix any failed checks above"
    echo "- Monitor system resources regularly"
    echo "- Keep models updated"
    echo "- Consider GPU acceleration for better performance"
}

# Main execution
main() {
    echo -e "${BLUE}Claude + Ollama Health Check${NC}"
    echo "=================================="
    
    local overall_status=0
    
    # Run all checks
    check_docker || overall_status=1
    check_container || overall_status=1
    check_api || overall_status=1
    check_models || overall_status=1
    check_claude_code || overall_status=1
    check_system_resources
    check_network
    
    # Generate summary
    generate_report
    
    echo ""
    if [ $overall_status -eq 0 ]; then
        print_success "All critical systems are operational"
        echo "Your setup is ready for coding! 🚀"
    else
        print_error "Some issues detected - please review above"
        echo "Run the individual fix commands as needed"
    fi
    
    return $overall_status
}

# Run main function
main "$@"
