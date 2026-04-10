#!/bin/bash
set -e

# Fix ownership of the Railway volume mount at /paperclip
if [ -d "/paperclip" ]; then
  chown -R paperclip:paperclip /paperclip 2>/dev/null || true
fi

# === HERMES CONFIG SETUP ===
HERMES_HOME="/home/paperclip/.hermes"
mkdir -p "$HERMES_HOME"/{sessions,logs,memories,skills,pairing,hooks,image_cache,audio_cache,cron}

if [ ! -f "/paperclip/hermes-config.yaml" ]; then
cat > /paperclip/hermes-config.yaml << 'YAML'
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
echo "[entrypoint] Created hermes config.yaml"
fi

cp /paperclip/hermes-config.yaml "$HERMES_HOME/config.yaml"

echo "OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-${OPEN_ROUTER_API_KEY:-}}" > "$HERMES_HOME/.env"
echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}" >> "$HERMES_HOME/.env"

chown -R paperclip:paperclip "$HERMES_HOME"

# Persist on volume
for dir in skills memories sessions; do
  mkdir -p "/paperclip/hermes-$dir"
  rm -rf "$HERMES_HOME/$dir"
  ln -sf "/paperclip/hermes-$dir" "$HERMES_HOME/$dir"
  chown -R paperclip:paperclip "/paperclip/hermes-$dir"
done

# === HERMES SMOKE TEST (runs as paperclip user, 30s max) ===
echo "[entrypoint] Running hermes smoke test..."
su - paperclip -c 'timeout 30 /usr/local/bin/hermes chat -q "Reply with just: HERMES_OK" -Q --yolo -m anthropic/claude-3.5-sonnet --provider openrouter 2>&1' || echo "[entrypoint] HERMES SMOKE TEST FAILED (exit $?)"
echo "[entrypoint] Smoke test complete"

# Drop privileges and run the actual command as the paperclip user
exec gosu paperclip "$@"
