FROM node:20-slim

# Install gosu, ca-certificates, Python 3, and git for Hermes Agent
RUN apt-get update && apt-get install -y --no-install-recommends \
    gosu ca-certificates python3 python3-pip python3-venv git curl \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent in a virtual environment
RUN python3 -m venv /opt/hermes \
    && /opt/hermes/bin/pip install --no-cache-dir pip --upgrade \
    && /opt/hermes/bin/pip install --no-cache-dir git+https://github.com/NousResearch/hermes-agent.git \
    && ln -sf /opt/hermes/bin/hermes /usr/local/bin/hermes

# Create a non-root user (required: Claude CLI refuses --dangerously-skip-permissions as root)
RUN groupadd -r paperclip && useradd -r -g paperclip -m -d /home/paperclip -s /bin/bash paperclip

# Create the paperclip home directory (Railway volume mount point)
RUN mkdir -p /paperclip && chown -R paperclip:paperclip /paperclip

WORKDIR /app

# Copy package files and install dependencies
COPY package.json ./
RUN npm install --omit=dev

# Copy application code
COPY . .

# Give ownership of everything to the non-root user
RUN chown -R paperclip:paperclip /app /home/paperclip

# Copy and set up entrypoint (fixes volume mount ownership at runtime)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Railway injects PORT at runtime (default 3100)
ENV PORT=3100
EXPOSE 3100

# Entrypoint runs as root to fix volume permissions, then drops to paperclip user
ENTRYPOINT ["/entrypoint.sh"]
CMD ["npm", "start"]
