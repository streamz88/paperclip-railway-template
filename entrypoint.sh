#!/bin/bash
set -e

# Fix ownership of the Railway volume mount at /paperclip
if [ -d "/paperclip" ]; then
  chown -R paperclip:paperclip /paperclip 2>/dev/null || true
fi

# Create Hermes config for the paperclip user
HERMES_HOME="/home/paperclip/.hermes"
mkdir -p "$HERMES_HOME"/{sessions,logs,memories,skills,pairing,hooks,image_cache,audio_cache,cron}

# Write Hermes config.yaml if it doesn't exist on the volume
if [ ! -f "/paperclip/hermes-config.yaml" ]; then
cat > /paperclip/hermes-config.yaml << 'YAML'
# Hermes Agent Configuration for LaunchersHQ Paperclip
llm:
  provider: openrouter
  model: anthropic/claude-3.5-sonnet
  temperature: 0.7
  max_tokens: 4096

agent:
  max_tool_iterations: 30
  tool_progress_display: minimal
  session_reset_policy: inactivity_timeout
  inactivity_timeout_minutes: 60

terminal:
  backend: local
  working_directory: /paperclip

security:
  approval_mode: auto
  sudo_enabled: false

skills:
  auto_generate: true
  auto_improve: true

memory:
  enabled: true
  provider: local
YAML
fi

# Symlink config from persistent volume
cp /paperclip/hermes-config.yaml "$HERMES_HOME/config.yaml"

# Write .env with API keys from Railway env vars
echo "OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-${OPEN_ROUTER_API_KEY:-}}" > "$HERMES_HOME/.env"
echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}" >> "$HERMES_HOME/.env"

# Fix ownership
chown -R paperclip:paperclip "$HERMES_HOME"

# Also persist skills/memories on the volume
for dir in skills memories sessions; do
  mkdir -p "/paperclip/hermes-$dir"
  # Symlink from hermes home to volume for persistence
  rm -rf "$HERMES_HOME/$dir"
  ln -sf "/paperclip/hermes-$dir" "$HERMES_HOME/$dir"
  chown -R paperclip:paperclip "/paperclip/hermes-$dir"
done

# Drop privileges and run the actual command as the paperclip user
exec gosu paperclip "$@"
