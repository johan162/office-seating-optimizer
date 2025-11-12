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


# --------------------------------------
# Targets

build:
	npm run build

dev:
	npm run dev

preview:
	npm run preview

clean: c-clean
	rm -rf dist

really-clean: clean c-really-clean
	rm -rf node_modules


cnc-build: build
	podman build --no-cache --build-arg VERSION=$(VERSION) -t office-seating-optimizer:$(VERSION) .

c-build: $(CONT_BUILD_STAMP)

$(CONT_BUILD_STAMP): build
	@echo "Building container image office-seating-optimizer:$(VERSION)..."
	@if podman build --build-arg VERSION=$(VERSION) -t office-seating-optimizer:$(VERSION) .; then \
		echo "Container image built successfully."; \
	else \
		echo "Container build failed."; \
		rm -f $(CONT_BUILD_STAMP); \
		exit 1; \
	fi
	@touch $(CONT_BUILD_STAMP)

c-run: $(CONT_BUILD_STAMP)
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
	@echo "Application is running at http://localhost:8080"
	@echo "To stop the container, run: podman stop office-optimizer"
	@echo "To see logs, run: podman logs -f office-optimizer"

c-stop:
	@echo "Stopping container..."
	-@podman stop office-optimizer > /dev/null 2>&1
	@echo "Container stopped."

c-rm:
	@echo "Removing container..."
	-@podman rm office-optimizer > /dev/null 2>&1
	@echo "Container removed."

c-rmi:
	@echo "Removing image..."
	-@podman rmi office-seating-optimizer:$(VERSION) > /dev/null 2>&1
	@echo "Image removed."

c-all-rmi:
	@echo "Removing all images..."
	-@podman images -q | xargs podman rmi -f > /dev/null 2>&1
	@echo "All images removed."

c-clean: c-stop c-rm c-rmi

c-really-clean: c-stop c-rm c-rmi c-all-rmi

# Target to push the container image to GitHub Container Registry as both with version tag and 'latest' tag
# Make the login file only an order dependency to ensure login is done first
c-push: | $(LOGIN_STAMP)  $(CONT_BUILD_STAMP)
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
ghcr-login: $(LOGIN_STAMP)

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


.PHONY: build dev preview c-build c-run c-stop c-rm c-rmi c-all-rmi c-clean c-really-clean c-push clean really-clean
