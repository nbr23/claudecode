FROM node:24-alpine

USER root
RUN apk update && apk add --no-cache \
    git \
    ripgrep \
    bash \
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
    make \
    go \
    wget \
    curl \
    gcc \
    g++ \
    musl-dev \
    build-base \
    aws-cli \
    docker \
    docker-cli-compose

RUN echo "@edge https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache github-cli@edge

RUN TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
    mv terraform /usr/local/bin/ && \
    rm "terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN chown -R node:node /usr/local

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
