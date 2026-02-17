# Claude + Ollama Development Makefile
# Provides convenient commands for managing the local AI development setup

.PHONY: help start stop restart logs status clean
.PHONY: pull-model list-models remove-model model-info
.PHONY: install-claude setup-env claude quick-start health-check

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m # No Color

# Docker settings
COMPOSE := docker-compose
CONTAINER := ollama
PORT := 11434

# Claude Code settings
AUTH_TOKEN := ollama
BASE_URL := http://localhost:$(PORT)

help: ## Show this help message
	@echo "$(BLUE)Claude + Ollama Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Container Management:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /container/ {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Model Management:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /model/ {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Claude Code:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /claude/ {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Utilities:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /utility/ {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make start                    # Start Ollama container"
	@echo "  make pull-model MODEL=qwen3-coder  # Download qwen3-coder model"
	@echo "  make claude MODEL=qwen3-coder       # Start Claude Code with qwen3-coder"
	@echo "  make quick-start MODEL=qwen3-coder  # Full setup and start"

# Container Management Commands
start: ## Start Ollama container
	@echo "$(BLUE)Starting Ollama container...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Ollama started on port $(PORT)$(NC)"

stop: ## Stop Ollama container
	@echo "$(BLUE)Stopping Ollama container...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✓ Ollama stopped$(NC)"

restart: ## Restart Ollama container
	@echo "$(BLUE)Restarting Ollama container...$(NC)"
	$(COMPOSE) restart
	@echo "$(GREEN)✓ Ollama restarted$(NC)"

logs: ## Show Ollama container logs
	@echo "$(BLUE)Ollama container logs:$(NC)"
	$(COMPOSE) logs -f

status: ## Check container status
	@echo "$(BLUE)Container status:$(NC)"
	@docker ps --filter name=$(CONTAINER) --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(BLUE)Health check:$(NC)"
	@curl -s http://localhost:$(PORT)/api/version 2>/dev/null && echo "$(GREEN)✓ Ollama API is responding$(NC)" || echo "$(RED)✗ Ollama API is not responding$(NC)"

clean: ## Clean up Docker resources
	@echo "$(BLUE)Cleaning up Docker resources...$(NC)"
	$(COMPOSE) down -v --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

# Model Management Commands
pull-model: ## Download a model (usage: make pull-model MODEL=qwen3-coder)
	@if [ -z "$(MODEL)" ]; then echo "$(RED)Error: MODEL parameter required$(NC)"; echo "Usage: make pull-model MODEL=<model-name>"; exit 1; fi
	@echo "$(BLUE)Pulling model $(MODEL)...$(NC)"
	@docker exec $(CONTAINER) ollama pull $(MODEL)
	@echo "$(GREEN)✓ Model $(MODEL) downloaded successfully$(NC)"

list-models: ## Show all downloaded models
	@echo "$(BLUE)Downloaded models:$(NC)"
	@docker exec $(CONTAINER) ollama list 2>/dev/null || echo "$(RED)✗ Could not list models. Is Ollama running?$(NC)"

remove-model: ## Remove a model (usage: make remove-model MODEL=model-name)
	@if [ -z "$(MODEL)" ]; then echo "$(RED)Error: MODEL parameter required$(NC)"; echo "Usage: make remove-model MODEL=<model-name>"; exit 1; fi
	@echo "$(BLUE)Removing model $(MODEL)...$(NC)"
	@docker exec $(CONTAINER) ollama rm $(MODEL)
	@echo "$(GREEN)✓ Model $(MODEL) removed$(NC)"

model-info: ## Show detailed information about a model
	@if [ -z "$(MODEL)" ]; then echo "$(RED)Error: MODEL parameter required$(NC)"; echo "Usage: make model-info MODEL=<model-name>"; exit 1; fi
	@echo "$(BLUE)Model information for $(MODEL):$(NC)"
	@docker exec $(CONTAINER) ollama show $(MODEL)

# Claude Code Commands
install-claude: ## Install Claude Code CLI
	@echo "$(BLUE)Installing Claude Code CLI...$(NC)"
	@if command -v claude >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Claude Code is already installed$(NC)"; \
	else \
		if [[ "$$OSTYPE" == "darwin"* ]] || [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
			curl -fsSL https://claude.ai/install.sh | bash; \
		else \
			echo "$(YELLOW)Please install Claude Code manually for your platform$(NC)"; \
			echo "Visit: https://claude.ai/install"; \
		fi; \
	fi

setup-env: ## Setup environment variables for Claude Code
	@echo "$(BLUE)Setting up environment variables...$(NC)"
	@export ANTHROPIC_AUTH_TOKEN=$(AUTH_TOKEN) && \
	export ANTHROPIC_BASE_URL=$(BASE_URL) && \
	echo "$(GREEN)✓ Environment variables set for this session$(NC)"
	@echo ""
	@echo "$(YELLOW)To make these permanent, add to your shell profile:$(NC)"
	@echo "export ANTHROPIC_AUTH_TOKEN=$(AUTH_TOKEN)"
	@echo "export ANTHROPIC_BASE_URL=$(BASE_URL)"

claude: ## Start Claude Code with specified model (usage: make claude MODEL=qwen3-coder)
	@if [ -z "$(MODEL)" ]; then echo "$(RED)Error: MODEL parameter required$(NC)"; echo "Usage: make claude MODEL=<model-name>"; exit 1; fi
	@echo "$(BLUE)Starting Claude Code with model $(MODEL)...$(NC)"
	@if ! command -v claude >/dev/null 2>&1; then \
		echo "$(RED)✗ Claude Code not found. Run 'make install-claude' first.$(NC)"; \
		exit 1; \
	fi
	@if ! curl -s http://localhost:$(PORT)/api/version >/dev/null 2>&1; then \
		echo "$(RED)✗ Ollama is not running. Run 'make start' first.$(NC)"; \
		exit 1; \
	fi
	@export ANTHROPIC_AUTH_TOKEN=$(AUTH_TOKEN) && \
	export ANTHROPIC_BASE_URL=$(BASE_URL) && \
	claude --model $(MODEL)

quick-start: ## Complete quick start (usage: make quick-start MODEL=qwen3-coder)
	@if [ -z "$(MODEL)" ]; then echo "$(RED)Error: MODEL parameter required$(NC)"; echo "Usage: make quick-start MODEL=<model-name>"; exit 1; fi
	@echo "$(BLUE)Quick starting with model $(MODEL)...$(NC)"
	@$(MAKE) start
	@sleep 3
	@$(MAKE) pull-model MODEL=$(MODEL)
	@$(MAKE) setup-env
	@echo "$(GREEN)✓ Setup complete! Starting Claude Code...$(NC)"
	@export ANTHROPIC_AUTH_TOKEN=$(AUTH_TOKEN) && \
	export ANTHROPIC_BASE_URL=$(BASE_URL) && \
	claude --model $(MODEL)

# Utility Commands
health-check: ## Perform system health check
	@echo "$(BLUE)System Health Check$(NC)"
	@echo "=================="
	@echo ""
	@echo "$(BLUE)Docker Status:$(NC)"
	@if command -v docker >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Docker is installed$(NC)"; \
		docker --version; \
	else \
		echo "$(RED)✗ Docker is not installed$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Docker Compose Status:$(NC)"
	@if command -v docker-compose >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Docker Compose is installed$(NC)"; \
		docker-compose --version; \
	else \
		echo "$(RED)✗ Docker Compose is not installed$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Claude Code Status:$(NC)"
	@if command -v claude >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Claude Code is installed$(NC)"; \
		claude --version 2>/dev/null || echo "Version unknown"; \
	else \
		echo "$(RED)✗ Claude Code is not installed$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Ollama Container Status:$(NC)"
	@docker ps --filter name=$(CONTAINER) --format "{{.Names}}: {{.Status}}" 2>/dev/null || echo "$(RED)✗ Container not found$(NC)"
	@echo ""
	@echo "$(BLUE)API Connectivity:$(NC)"
	@curl -s http://localhost:$(PORT)/api/version 2>/dev/null && echo "$(GREEN)✓ API is responding$(NC)" || echo "$(RED)✗ API is not responding$(NC)"
	@echo ""
	@echo "$(BLUE)System Resources:$(NC)"
	@echo "Available memory: $$(free -h 2>/dev/null | grep '^Mem:' | awk '{print $$7}' || echo 'N/A (not Linux)')"
	@echo "Disk space: $$(df -h . | tail -1 | awk '{print $$4}')"
	@echo ""
	@if docker ps --filter name=$(CONTAINER) --quiet >/dev/null 2>&1; then \
		echo "$(BLUE)Container Resource Usage:$(NC)"; \
		docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(CONTAINER) 2>/dev/null || echo "Could not get stats"; \
	fi

# Development shortcuts
dev-setup: ## Complete development setup (install, start, pull model)
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@$(MAKE) install-claude
	@$(MAKE) start
	@sleep 3
	@$(MAKE) pull-model MODEL=qwen3-coder
	@$(MAKE) setup-env
	@echo "$(GREEN)✓ Development setup complete!$(NC)"
	@echo "Run 'make claude MODEL=qwen3-coder' to start coding"

dev-reset: ## Reset development environment (stop, clean, restart)
	@echo "$(BLUE)Resetting development environment...$(NC)"
	@$(MAKE) stop
	@$(MAKE) clean
	@$(MAKE) start
	@echo "$(GREEN)✓ Development environment reset$(NC)"
