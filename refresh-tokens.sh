#!/bin/sh
set -eu

CONFIG="src/instagram.config.ts"

if [ ! -f "$CONFIG" ]; then
  echo "Error: $CONFIG not found. Run this from the repo root." >&2
  exit 1
fi

# Extract tokens from the config file
tokens=$(grep -o 'IGAA[^"]*' "$CONFIG")
count=$(echo "$tokens" | wc -l | tr -d ' ')

if [ -z "$tokens" ]; then
  echo "Error: No tokens found in $CONFIG" >&2
  exit 1
fi

echo "Found $count token(s) to refresh"

echo "$tokens" | while IFS= read -r old_token; do
  echo "Refreshing ${old_token:0:20}..."

  response=$(curl -sf "https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=${old_token}")
  new_token=$(echo "$response" | jq -r '.access_token')
  expires_in=$(echo "$response" | jq -r '.expires_in')

  if [ -z "$new_token" ] || [ "$new_token" = "null" ]; then
    echo "  Error: failed to refresh token" >&2
    echo "  Response: $response" >&2
    exit 1
  fi

  sed -i '' "s|${old_token}|${new_token}|" "$CONFIG"
  days=$((expires_in / 86400))
  echo "  OK — new token expires in ${days} days"
done

echo "Updated $CONFIG"
