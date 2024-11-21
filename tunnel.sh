#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)  # Ignore commented lines and empty lines
else
  echo ".env file not found! Exiting."
  exit 1
fi

# Ensure necessary variables are set
if [ -z "$SHOPIFY_API_KEY" ] || [ -z "$SHOPIFY_API_SCOPES" ]; then
  echo "Required variables (SHOPIFY_API_KEY or SHOPIFY_API_SCOPES) are missing in .env! Exiting."
  exit 1
fi

echo "Starting Cloudflare tunnel and waiting for the URL..."

# Start Cloudflare tunnel in the background and capture its output
cloudflared tunnel --url http://localhost:8006 > tunnel.log 2>&1 &

# Wait for the tunnel URL to be available, with a timeout
MAX_WAIT=60  # Maximum wait time in seconds
WAIT_INTERVAL=2  # Check every 2 seconds
ELAPSED=0
TUNNEL_URL=""

while [ $ELAPSED -lt $MAX_WAIT ]; do
  # Try to extract the Cloudflare URL from the log
  TUNNEL_URL=$(grep -oP '(?<=https://)[a-z0-9-]+\.trycloudflare\.com' tunnel.log | head -n 1)

  if [ -n "$TUNNEL_URL" ]; then
    break
  fi

  # Wait and increment the elapsed time
  sleep $WAIT_INTERVAL
  ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

# Ensure the URL was retrieved successfully
if [ -z "$TUNNEL_URL" ]; then
  echo "Failed to retrieve Cloudflare URL within $MAX_WAIT seconds. Exiting."
  exit 1
fi

# Ensure the URL is HTTPS
TUNNEL_URL="https://$TUNNEL_URL"

echo "Cloudflare Tunnel URL: $TUNNEL_URL"


# Update APP_URL in the .env file
APP_ENV_FILE=".env"

if grep -q '^APP_URL=' $APP_ENV_FILE; then
  sed -i "s|^APP_URL=.*|APP_URL=$TUNNEL_URL|" $APP_ENV_FILE
else
  echo "APP_URL=$TUNNEL_URL" >> $APP_ENV_FILE
fi
echo "Updated APP_URL in $APP_ENV_FILE."

# Update VITE_BASE_URL in the ../web/.env file
WEB_ENV_FILE="../web/.env"

if grep -q '^VITE_BASE_URL=' $WEB_ENV_FILE; then
  sed -i "s|^VITE_BASE_URL=.*|VITE_BASE_URL= \"$TUNNEL_URL/back\"|" $WEB_ENV_FILE
else
  echo "VITE_BASE_URL=$TUNNEL_URL" >> $WEB_ENV_FILE
fi
echo "Updated VITE_BASE_URL in $WEB_ENV_FILE."

# Update the application_url, redirect_urls, client_id, and scopes in the .toml file
CONFIG_FILE="shopify.app.toml"

# Replace application_url with the new tunnel URL
sed -i "s|^application_url = \".*\"|application_url = \"$TUNNEL_URL/back/home\"|" $CONFIG_FILE

# Replace redirect_urls with the new tunnel URL
sed -i "s|^  \"https://.*\"|  \"$TUNNEL_URL/back/authenticate\"|" $CONFIG_FILE

# Replace client_id with the value from .env
sed -i "s|^client_id = \".*\"|client_id = \"$SHOPIFY_API_KEY\"|" $CONFIG_FILE

# Replace scopes with the value from .env
sed -i "s|^scopes = \".*\"|scopes = \"$SHOPIFY_API_SCOPES\"|" $CONFIG_FILE

echo "Updated $CONFIG_FILE with the new Cloudflare Tunnel URL."

echo "Deploying the Shopify app..."

# Start the app in development mode
shopify app deploy

echo "Shopify app URLs and .env APP_URL updated successfully."

# Optional: Clean up the log file
rm tunnel.log
