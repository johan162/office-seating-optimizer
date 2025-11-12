VERSION ?= dev
CONTAINER_NAME := office-seating-optimizer

# Add pre-req check that podman is installed
ifeq (, $(shell which podman))
$(error "No podman found. Please install podman to use the container targets.")
endif

# Add pre-req that GITHUB_USER is set
ifeq ($(GITHUB_USER),)
$(error "GITHUB_USER is not set. Please set GITHUB_USER to your GitHub username.")
endif

# Check that GEMINI_API_KEY is set for container run target
ifeq ($(GEMINI_API_KEY),)
$(error "GEMINI_API_KEY is not set. Please set GEMINI_API_KEY to your Gemini API key.")
endif

CONTAINER_REGISTRY := ghcr.io/$(GITHUB_USER)/$(CONTAINER_NAME)

# Set default target
.DEFAULT_GOAL := build

# File to track last login time to GHCR
LOGIN_STAMP := .ghcr-login-timestamp
CONT_BUILD_STAMP := .container-build-timestamp

# Directories
SRC_DIR := src
DIST_DIR := dist
SCRIPTS_DIR := scripts

# Source files
SRC_FILES := $(shell find $(SRC_DIR) -name '*.ts' -o -name '*.tsx' -o -name '*.css')
CONFIG_FILES := package.json tsconfig.json vite.config.ts nginx.conf index.html entrypoint.sh
SOURCE_FILES := $(SRC_FILES) $(CONFIG_FILES)
CONT_CONFIG_FILES := Dockerfile

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color


# =====================================
# Help Target
# =====================================

help: ## Show this help message
	@echo "$(BLUE)Office Seating Optimizer - Makefile targets$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make dev                                 # Run development server"
	@echo "  make VERSION=0.5.1 c-build               # Build container and tag with version 0.5.1"
	@echo "  make c-run                               # Run the latest containerized application"
	@echo "  make c-really-clean                      # Stop and clean all container artifacts"
	@echo ""
	@echo "$(YELLOW)The following targets require access token for ghcr.io$(NC)"
	@echo "  make VERSION=0.5.1 c-push                # Push the container image to GitHub Container Registry"
	@echo "  make ghcr-login                          # Login to GitHub Container Registry via Podman"


build: $(SOURCE_FILES) ## Build the production version of project
	npm run build

dev: build ## Run the development server
	npm run dev

preview: build ## Preview the production build	
	npm run preview

clean: c-clean ## Clean build artifacts and timestamps
	rm -rf dist $(LOGIN_STAMP) $(CONT_BUILD_STAMP)

really-clean: clean c-really-clean ## Really clean all artifacts, timestamps, and node modules
	rm -rf node_modules artifacts


cnc-build: build $(CONT_CONFIG_FILES) ## Build container image without using cache
	podman build --no-cache --build-arg VERSION=$(VERSION) -t office-seating-optimizer:$(VERSION) .

c-build: $(CONT_BUILD_STAMP) ## Build container image

$(CONT_BUILD_STAMP): $(SOURCE_FILES) $(CONT_CONFIG_FILES)  ## Build container image
	@echo "Building container image office-seating-optimizer:$(VERSION)..."
	@if podman build --build-arg VERSION=$(VERSION) -t office-seating-optimizer:$(VERSION) -t office-seating-optimizer:latest .; then \
		echo "Container image built successfully."; \
	else \
		echo "Container build failed."; \
		rm -f $(CONT_BUILD_STAMP); \
		exit 1; \
	fi
	@touch $(CONT_BUILD_STAMP)

c-run: | $(CONT_BUILD_STAMP) ## Run the containerized application
	@if [ -z "$(GEMINI_API_KEY)" ]; then \
		echo "Error: GEMINI_API_KEY environment variable is not set."; \
		echo "Usage: GEMINI_API_KEY=<your_gemini_api_key> make container-run"; \
		exit 1; \
	fi
	@echo "Stopping and removing existing container if it exists..."
	-@podman stop office-optimizer > /dev/null 2>&1
	-@podman rm office-optimizer > /dev/null 2>&1
	@echo "Starting new container..."
	@podman run -d -p 8080:80 -e VITE_API_KEY=$(GEMINI_API_KEY) --name office-optimizer office-seating-optimizer:latest
	@echo "$(YELLOW)Application is running at http://localhost:8080$(NC)"
	@echo "To stop the container, run: $(BLUE) podman stop office-optimizer$(NC)"
	@echo "To see logs, run: $(BLUE) podman logs -f office-optimizer$(NC)"

c-stop: ## Stop the running container
	@echo "Stopping container..."
	-@podman stop office-optimizer > /dev/null 2>&1
	@echo "Container stopped."

c-rm: c-stop ## Remove the container
	@echo "Removing container..."
	-@podman rm office-optimizer > /dev/null 2>&1
	@echo "Container removed."

c-rmi: ## Remove the container image
	@echo "Removing image..."
	-@podman rmi office-seating-optimizer:$(VERSION) > /dev/null 2>&1
	@echo "Image removed."

c-all-rmi: ## Remove all container images
	@echo "Removing all images..."
	-@podman images -q | xargs podman rmi -f > /dev/null 2>&1
	@echo "All images removed."

c-clean: c-stop c-rm c-rmi ## Clean container artifacts
	rm -f $(CONT_BUILD_STAMP) $(LOGIN_STAMP)

c-really-clean: c-stop c-rm c-all-rmi ## Really clean all container artifacts

# Target to push the container image to GitHub Container Registry as both with version tag and 'latest' tag
# Make the login file only an order dependency to ensure login is done first
c-push: | $(LOGIN_STAMP)  $(CONT_BUILD_STAMP) ## Push container image to GitHub Container Registry
	@if [ "$(VERSION)" = "dev" ]; then \
		echo "Error: Cannot push image with version 'dev'. Please set VERSION to a proper release version."; \
		echo "Usage: make c-push VERSION=<release_version>"; \
		exit 1; \
	fi
	@echo "Pushing image $(CONTAINER_NAME):$(VERSION),:latest to GitHub Container Registry..."
	podman push $(CONTAINER_NAME):$(VERSION) ghcr.io/$(GITHUB_USER)/$(CONTAINER_NAME):$(VERSION)
	podman tag $(CONTAINER_NAME):$(VERSION) ghcr.io/$(GITHUB_USER)/$(CONTAINER_NAME):latest
	podman push ghcr.io/$(GITHUB_USER)/$(CONTAINER_NAME):latest


# Target to login to GitHub Container Registry via Podman
# Check first that GHCR_TOKEN environment variable is set
# Use a time-stamp filed to remember if it has been done recently
ghcr-login: $(LOGIN_STAMP) ## Login to GitHub Container Registry via Podman

$(LOGIN_STAMP): 
	@if [ -z "$(GHCR_TOKEN)" ]; then \
		echo "Error: GHCR_TOKEN environment variable is not set."; \
		echo "Please set GHCR_TOKEN with a valid GitHub Personal Access Token."; \
		exit 1; \
	fi
	@if [ -f $(LOGIN_STAMP) ] && [ $$(find $(LOGIN_STAMP) -mmin -120) ]; then \
		echo "Already logged in to GHCR recently. Skipping login."; \
		exit 0; \
	fi
	@echo "Logging in to GitHub Container Registry..."
	@if podman login ghcr.io -u $(GITHUB_USER) -p $(GHCR_TOKEN) >/dev/null 2>&1; then \
		echo "Login successful."; \
	else \
		echo "Login failed. Please check your GHCR_TOKEN."; \
		exit 1; \
	fi	
	@touch $(LOGIN_STAMP)


.PHONY: build dev preview c-build c-run c-stop c-rm c-rmi c-all-rmi c-clean c-really-clean c-push clean really-clean ghcr-login 
