#!/bin/sh
set -e

# Find the main JavaScript file in the assets directory
JS_FILE=$(find /usr/share/nginx/html/assets -name "index-*.js")

# Check if VITE_API_KEY is set
if [ -z "$VITE_API_KEY" ]; then
  echo "Error: VITE_API_KEY environment variable is not set."
  exit 1
fi

# Create a temporary file
TMP_FILE=$(mktemp)

# Replace the placeholder with the actual API key
# The placeholder is a Vite-specific syntax: import.meta.env.VITE_API_KEY
# We are replacing it with the actual key provided at runtime.
sed "s|import\.meta\.env\.VITE_API_KEY|'${VITE_API_KEY}'|g" "$JS_FILE" > "$TMP_FILE"

# Overwrite the original file with the updated content
mv "$TMP_FILE" "$JS_FILE"

# Ensure the file has correct ownership and permissions for nginx
chown nginx:nginx "$JS_FILE"
chmod a+r "$JS_FILE"

# Execute the CMD from the Dockerfile (e.g., "nginx -g 'daemon off;'")
exec "$@"
