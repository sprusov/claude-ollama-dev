# Troubleshooting Guide

This guide covers common issues and solutions for the Ollama + Claude Code setup.

## 🚨 Quick Diagnosis

Run the health check first to identify issues:

```bash
make health-check
# or
./scripts/health-check.sh
```

## 🔧 Common Issues

### 1. Authentication Failed

**Error**: "authentication failed" or "invalid API key"

**Causes & Solutions**:
- Environment variables not set
  ```bash
  export ANTHROPIC_AUTH_TOKEN=ollama
  export ANTHROPIC_BASE_URL=http://localhost:11434
  ```
- Variables not in current shell session
  ```bash
  echo $ANTHROPIC_AUTH_TOKEN  # Should return "ollama"
  echo $ANTHROPIC_BASE_URL    # Should return "http://localhost:11434"
  ```
- Variables not persisted in shell profile
  ```bash
  # Add to ~/.zshrc or ~/.bashrc
  echo 'export ANTHROPIC_AUTH_TOKEN=ollama' >> ~/.zshrc
  echo 'export ANTHROPIC_BASE_URL=http://localhost:11434' >> ~/.zshrc
  source ~/.zshrc
  ```

### 2. Connection Failed

**Error**: "Could not connect to Ollama" or "Connection refused"

**Causes & Solutions**:
- Ollama container not running
  ```bash
  docker ps | grep ollama  # Should show running container
  make start               # Start the container
  ```
- Port 11434 blocked or in use
  ```bash
  lsof -i :11434           # Check what's using the port
  # If something else is using it, stop it or change port in docker-compose.yml
  ```
- Docker daemon not running
  ```bash
  docker info              # Should show Docker info
  # Start Docker Desktop or service
  ```

### 3. Model Not Found

**Error**: "Model not found" or "No such model"

**Causes & Solutions**:
- Model not downloaded
  ```bash
  make list-models         # Check available models
  make pull-model MODEL=qwen3-coder  # Download the model
  ```
- Incorrect model name
  ```bash
  docker exec ollama ollama list  # See exact names
  # Use exact name from list
  ```
- Model corrupted
  ```bash
  make remove-model MODEL=<model-name>
  make pull-model MODEL=<model-name>
  ```

### 4. Slow Responses

**Symptoms**: Responses take 30+ seconds

**Solutions**:
- Use smaller model
  ```bash
  claude --model deepseek-coder:6.7b  # Instead of larger models
  ```
- Enable GPU support (NVIDIA)
  ```yaml
  # Uncomment in docker-compose.yml
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
  ```
- Check system resources
  ```bash
  make health-check  # Check memory and CPU usage
  docker stats ollama  # Monitor container resources
  ```

### 5. Docker Issues

**Container won't start**:
```bash
# Check Docker logs
docker logs ollama

# Common fixes:
docker-compose down -v  # Clean volumes
docker system prune -f  # Clean Docker
make start              # Restart fresh
```

**Port conflicts**:
```bash
# Check what's using port 11434
lsof -i :11434

# Stop conflicting service or change port:
# Edit docker-compose.yml, change "11434:11434" to "11435:11434"
```

**Out of memory**:
```bash
# Check Docker memory limits (Docker Desktop)
# Increase to at least 8GB
# Or use smaller models
```

### 6. Claude Code Issues

**Installation problems**:
```bash
# Reinstall Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Check installation
which claude
claude --version
```

**Permission issues**:
```bash
# Check if claude is executable
chmod +x $(which claude)

# Check PATH
echo $PATH | grep -o "[^:]*claude[^:]*"
```

**Proxy/firewall blocking**:
```bash
# Test direct connection
curl -v http://localhost:11434/api/version

# If blocked, configure proxy or disable firewall for localhost
```

## 🔍 Advanced Troubleshooting

### Container Debugging

```bash
# Enter container for debugging
docker exec -it ollama bash

# Inside container:
ollama list              # Check models
ollama version           # Check version
curl localhost:11434/api/version  # Test API
```

### Network Issues

```bash
# Test network connectivity
curl -I http://localhost:11434
telnet localhost 11434

# Check Docker network
docker network ls
docker network inspect ollama-dev_default
```

### Performance Analysis

```bash
# Monitor system resources
top -p $(pgrep -f ollama)
htop
iotop

# Docker-specific monitoring
docker stats --no-stream ollama
docker events ollama
```

### Log Analysis

```bash
# Real-time logs
docker-compose logs -f ollama

# Historical logs
docker logs ollama --tail 100

# System logs (macOS)
log show --predicate 'process == "docker"' --last 1h
```

## 🚨 Emergency Procedures

### Complete Reset

If everything is broken, perform a full reset:

```bash
# Stop everything
make stop

# Clean all Docker resources
make clean

# Remove all data (WARNING: deletes all models)
docker volume rm ollama-dev_ollama_data

# Fresh start
make start
make pull-model MODEL=qwen3-coder
make setup-env
```

### Manual Recovery

If Makefile commands don't work:

```bash
# Manual Docker commands
docker-compose down
docker-compose up -d

# Manual model management
docker exec ollama ollama pull qwen3-coder
docker exec ollama ollama list

# Manual environment setup
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
claude --model qwen3-coder
```

## 📞 Getting Help

### Collect Debug Information

```bash
# Create debug report
./scripts/health-check.sh > debug-report.txt 2>&1
docker logs ollama >> debug-report.txt
docker system info >> debug-report.txt
```

### Common Debug Commands

```bash
# System info
uname -a
docker --version
docker-compose --version
claude --version 2>/dev/null || echo "Claude not installed"

# Network info
netstat -an | grep 11434
lsof -i :11434

# Process info
ps aux | grep ollama
ps aux | grep docker
```

### When to Ask for Help

Ask for help if:
- Health check shows multiple failures
- Basic fixes don't work
- You see unusual error messages
- Performance is extremely poor despite optimizations

Include in your help request:
- Operating system and version
- Docker and Docker Compose versions
- Output of `make health-check`
- Specific error messages
- What you've already tried

## 🎯 Prevention Tips

### Regular Maintenance

```bash
# Weekly maintenance
make health-check
docker system prune -f
./scripts/model-manager.sh cleanup
```

### Best Practices

1. **Monitor resources**: Don't let memory/disk fill up
2. **Use appropriate models**: Small models for quick tasks
3. **Keep Docker updated**: Regular updates prevent issues
4. **Backup configurations**: Save your IDE configs
5. **Document customizations**: Note any changes you make

### Performance Optimization

```bash
# Enable GPU if available
# Edit docker-compose.yml to uncomment GPU section

# Use smaller models for autocomplete
# Configure in IDE settings

# Limit concurrent requests
# Avoid running multiple AI tasks simultaneously
```

## 🔄 Recovery Checklist

When something goes wrong, run this checklist:

- [ ] Is Docker running? (`docker info`)
- [ ] Is Ollama container up? (`docker ps | grep ollama`)
- [ ] Is API responding? (`curl http://localhost:11434/api/version`)
- [ ] Are environment variables set? (`echo $ANTHROPIC_*`)
- [ ] Is Claude Code installed? (`which claude`)
- [ ] Are models available? (`docker exec ollama ollama list`)
- [ ] Is port accessible? (`lsof -i :11434`)

If all checks pass, the issue might be:
- Network configuration
- Proxy/firewall settings
- Model-specific problems
- Resource limitations

Run `make health-check` for a comprehensive diagnosis.
