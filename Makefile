build:
	npm run build

dev:
	npm run dev

preview:
	npm run preview

container-build:
	podman build -t office-space-optimizer .

container-run:
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
