FROM node:25-alpine3.22 AS base

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
    wget \
    curl \
    jq \
    make \
    gcc \
    g++ \
    musl-dev \
    linux-headers \
    build-base \
    iptables \
    ipset \
    iproute2 \
    bind-tools

RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-virtualenv \
    go \
    rust \
    cargo \
    sqlite \
    postgresql-client \
    mysql-client \
    redis

RUN apk add --no-cache \
    aws-cli \
    docker \
    docker-cli-compose \
    yq \
    pngquant \
    imagemagick \
    ffmpeg

RUN echo "@edge https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache github-cli@edge

FROM base AS tools-builder

USER root
WORKDIR /tmp

RUN TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
    mv terraform /usr/local/bin/ && \
    rm "terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" && \
    tar -zxf "helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" && \
    mv "linux-${ARCH}/helm" /usr/local/bin/ && \
    rm -rf "linux-${ARCH}" "helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"

RUN ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/arm/') && \
    curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${ARCH}.tar.gz" && \
    tar -xf "google-cloud-cli-linux-${ARCH}.tar.gz" && \
    ./google-cloud-sdk/install.sh --quiet --path-update false && \
    mv google-cloud-sdk /opt/ && \
    rm -f "google-cloud-cli-linux-${ARCH}.tar.gz"

FROM base

USER root

COPY --from=tools-builder /usr/local/bin/terraform /usr/local/bin/
COPY --from=tools-builder /usr/local/bin/kubectl /usr/local/bin/
COPY --from=tools-builder /usr/local/bin/helm /usr/local/bin/
COPY --from=tools-builder /opt/google-cloud-sdk /opt/google-cloud-sdk

RUN ln -s /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud && \
    ln -s /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil && \
    ln -s /opt/google-cloud-sdk/bin/bq /usr/local/bin/bq

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN chown -R node:node /usr/local

ENV CLAUDE_CODE_ENABLE_TELEMETRY=0
ENV DISABLE_ERROR_REPORTING=1
ENV DISABLE_TELEMETRY=1
ENV DISABLE_AUTOUPDATER=1

USER node

WORKDIR /home/node/.tools
COPY package.json ./
RUN npm install --omit=dev
ENV PATH="/home/node/.tools/node_modules/.bin:${PATH}"

RUN curl -fsSL https://claude.ai/install.sh | bash -s $(jq -r '.devDependencies."@anthropic-ai/claude-code"' package.json)

ENV PATH="/home/node/.local/bin:${PATH}"

WORKDIR /home/node

ENTRYPOINT ["claude"]
