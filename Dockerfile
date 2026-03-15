ARG BUILD_FROM
FROM $BUILD_FROM

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    curl \
    tmux \
    nodejs \
    npm \
 && npm install -g @anthropic-ai/claude-code \
 && apt-get purge -y npm \
 && rm -rf /var/lib/apt/lists/*

# Install ttyd
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 \
    -o /usr/local/bin/ttyd \
 && chmod +x /usr/local/bin/ttyd

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
