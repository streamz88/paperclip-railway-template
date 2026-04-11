#!/bin/bash
# hermes-debug.sh — wrapper that fixes v0.2.0 adapter env var bug
# The adapter passes agent-level env vars which may be empty strings,
# overriding the real container-level keys. This wrapper restores them
# from the Hermes .env file written by entrypoint.sh at boot.

HERMES_ENV="/home/paperclip/.hermes/.env"
LOG="/tmp/hermes-debug.log"

echo "[hermes-wrapper] $(date) PID=$$ args: $@" >> "$LOG"
echo "[hermes-wrapper] $(date) PID=$$ args: $@" >&2

# Log current env var state (redacted)
echo "[hermes-wrapper] OPENROUTER_API_KEY set: $([ -n \"$OPENROUTER_API_KEY\" ] && echo YES || echo NO/EMPTY)" >> "$LOG"
echo "[hermes-wrapper] ANTHROPIC_API_KEY set: $([ -n \"$ANTHROPIC_API_KEY\" ] && echo YES || echo NO/EMPTY)" >> "$LOG"
echo "[hermes-wrapper] OPENROUTER_API_KEY set: $([ -n \"$OPENROUTER_API_KEY\" ] && echo YES || echo NO/EMPTY)" >&2
echo "[hermes-wrapper] ANTHROPIC_API_KEY set: $([ -n \"$ANTHROPIC_API_KEY\" ] && echo YES || echo NO/EMPTY)" >&2

# Fix: if keys are empty/missing, restore from entrypoint-written .env
if [ -f "$HERMES_ENV" ]; then
  echo "[hermes-wrapper] Found $HERMES_ENV, sourcing container keys..." >> "$LOG"
  echo "[hermes-wrapper] Found $HERMES_ENV, sourcing container keys..." >&2
  
  # Source the .env file to get real values
  while IFS='=' read -r key value; do
    # Only override if current value is empty and .env has a real value
    if [ -n "$value" ]; then
      current_val=$(eval echo "\$$key")
      if [ -z "$current_val" ]; then
        export "$key=$value"
        echo "[hermes-wrapper] Restored $key from .env (was empty)" >> "$LOG"
        echo "[hermes-wrapper] Restored $key from .env (was empty)" >&2
      fi
    fi
  done < "$HERMES_ENV"
else
  echo "[hermes-wrapper] WARNING: $HERMES_ENV not found!" >> "$LOG"
  echo "[hermes-wrapper] WARNING: $HERMES_ENV not found!" >&2
fi

# Log post-fix state
echo "[hermes-wrapper] POST-FIX OPENROUTER_API_KEY set: $([ -n \"$OPENROUTER_API_KEY\" ] && echo YES || echo NO/EMPTY)" >> "$LOG"
echo "[hermes-wrapper] POST-FIX ANTHROPIC_API_KEY set: $([ -n \"$ANTHROPIC_API_KEY\" ] && echo YES || echo NO/EMPTY)" >> "$LOG"
echo "[hermes-wrapper] POST-FIX OPENROUTER_API_KEY set: $([ -n \"$OPENROUTER_API_KEY\" ] && echo YES || echo NO/EMPTY)" >&2
echo "[hermes-wrapper] POST-FIX ANTHROPIC_API_KEY set: $([ -n \"$ANTHROPIC_API_KEY\" ] && echo YES || echo NO/EMPTY)" >&2

echo "[hermes-wrapper] Launching hermes..." >> "$LOG"
echo "[hermes-wrapper] Launching hermes..." >&2

exec /usr/local/bin/hermes-real "$@"
