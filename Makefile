build:
	npm run build

dev:
	npm run dev

preview:
	npm run preview

c-build:
	podman build -t office-space-optimizer .

c-run:
	@if [ -z "$(API_KEY)" ]; then \
		echo "Error: API_KEY environment variable is not set."; \
		echo "Usage: API_KEY=<your_gemini_api_key> make container-run"; \
		exit 1; \
	fi
	@echo "Stopping and removing existing container if it exists..."
	-@podman stop office-optimizer > /dev/null 2>&1
	-@podman rm office-optimizer > /dev/null 2>&1
	@echo "Starting new container..."
	@podman run -d -p 8080:80 -e VITE_API_KEY=$(API_KEY) --name office-optimizer office-space-optimizer
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
	-@podman rmi office-space-optimizer > /dev/null 2>&1
	@echo "Image removed."

c-clean: c-stop c-rm c-rmi


.PHONY: build dev preview c-build c-run c-stop c-rm c-rmi