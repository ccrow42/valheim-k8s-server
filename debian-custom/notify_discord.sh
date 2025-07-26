#!/usr/bin/env bash

set -ex

MESSAGE="$*"

# Safely encode message and send
curl -k -X POST -H "Content-Type: application/json" \
  -d "$(jq -nc --arg content "$MESSAGE" '{content: $content}')" \
  "$DISCORD_WEBHOOK"

