FROM node:24-alpine

USER root
RUN apk update && apk add --no-cache \
    git ripgrep bash \
    less \
    procps \
    fzf \
    zsh \
    mandoc \
    unzip \
    gnupg \
    iptables \
    ipset \
    iproute2 \
    bind-tools \
    jq \
    python3 \
    py3-pip \
    py3-virtualenv \
    sqlite \
    github-cli \
    make

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

USER node


WORKDIR /home/node/.tools
COPY package.json ./
RUN npm install
ENV PATH="/home/node/.tools/node_modules/.bin:${PATH}"

WORKDIR /home/node

ENV CLAUDE_CODE_ENABLE_TELEMETRY=0
ENV DISABLE_ERROR_REPORTING=1
ENV DISABLE_TELEMETRY=1
ENV DISABLE_AUTOUPDATER=1

ENTRYPOINT ["claude"]
