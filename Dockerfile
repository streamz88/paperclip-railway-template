FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    gosu ca-certificates python3 python3-pip python3-venv git curl \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent v0.7.0 (The Resilience Release) - pinned for stability
RUN python3 -m venv /opt/hermes \
    && /opt/hermes/bin/pip install --no-cache-dir pip --upgrade \
    && /opt/hermes/bin/pip install --no-cache-dir "git+https://github.com/NousResearch/hermes-agent.git@v2026.4.3" \
    && ln -sf /opt/hermes/bin/hermes /usr/local/bin/hermes

RUN groupadd -r paperclip && useradd -r -g paperclip -m -d /home/paperclip -s /bin/bash paperclip

# Bake Hermes config with openrouter provider
RUN mkdir -p /home/paperclip/.hermes/{sessions,logs,memories,skills,pairing,hooks,image_cache,audio_cache,cron} \
    && printf 'llm:\n  provider: openrouter\n  model: anthropic/claude-3.5-sonnet\n  temperature: 0.7\n  max_tokens: 4096\nagent:\n  max_tool_iterations: 30\n  tool_progress_display: minimal\nterminal:\n  backend: local\n  working_directory: /paperclip\nsecurity:\n  approval_mode: auto\n  sudo_enabled: false\nskills:\n  auto_generate: true\n  auto_improve: true\nmemory:\n  enabled: true\n  provider: local\n' > /home/paperclip/.hermes/config.yaml \
    && chown -R paperclip:paperclip /home/paperclip/.hermes

RUN mkdir -p /paperclip && chown -R paperclip:paperclip /paperclip

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY . .
RUN chown -R paperclip:paperclip /app /home/paperclip

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PORT=3100
EXPOSE 3100
ENTRYPOINT ["/entrypoint.sh"]
CMD ["npm", "start"]
