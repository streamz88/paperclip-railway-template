#!/bin/bash
set -e

if [ -d "/paperclip" ]; then
  chown -R paperclip:paperclip /paperclip 2>/dev/null || true
fi

# Map OPEN_ROUTER_API_KEY -> OPENROUTER_API_KEY if needed
export OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-${OPEN_ROUTER_API_KEY:-}}"

# Write API keys to Hermes .env (Hermes reads from here)
HERMES_HOME="/home/paperclip/.hermes"
echo "OPENROUTER_API_KEY=${OPENROUTER_API_KEY}" > "$HERMES_HOME/.env"
echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}" >> "$HERMES_HOME/.env"

# Persist skills/memories/sessions on Railway volume
for dir in skills memories sessions; do
  mkdir -p "/paperclip/hermes-$dir"
  rm -rf "$HERMES_HOME/$dir"
  ln -sf "/paperclip/hermes-$dir" "$HERMES_HOME/$dir"
  chown -R paperclip:paperclip "/paperclip/hermes-$dir"
done

chown -R paperclip:paperclip "$HERMES_HOME"

exec gosu paperclip "$@"
