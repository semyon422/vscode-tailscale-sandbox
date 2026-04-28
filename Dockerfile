FROM codercom/code-server:latest

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    file \
    git \
    gnupg \
    iproute2 \
    jq \
    less \
    locales \
    luajit \
    man-db \
    nano \
    netcat-openbsd \
    openssh-client \
    pkg-config \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    rsync \
    shellcheck \
    tar \
    tree \
    unzip \
    vim \
    wget \
    zip \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @mariozechner/pi-coding-agent @anthropic-ai/claude-code @openai/codex @google/gemini-cli

USER coder
