# claudecode

Docker images for running AI coding CLIs in a container. Images are built for `linux/amd64` and `linux/arm64`.

## Images

### `nbr23/claudecode`

Built from `Dockerfile` (Alpine), except `:all` which is built from `Dockerfile.antigravity` (Debian).

| Tag | Entrypoint | Contents |
| --- | --- | --- |
| `latest`, `claude`, `claude-code-<version>` | `claude` | Claude Code |
| `opencode`, `opencode-<version>` | `opencode` | OpenCode with the `opencode-gemini-auth` plugin |
| `codex`, `codex-<version>` | `codex` | OpenAI Codex CLI |
| `all` | none (`CMD sleep infinity`) | Claude Code, Codex, OpenCode and Antigravity CLI |

### `nbr23/antigravity`

Built from `Dockerfile.antigravity` (Debian).

| Tag | Command | Contents |
| --- | --- | --- |
| `latest` | `agy` | Antigravity CLI |

Tool versions come from `package.json` (Claude Code, Codex, OpenCode) and `Dockerfile.antigravity` (Antigravity CLI).

## Usage

All images run as user `node`. Mount the project under `/home/node/dev/`.

### Claude Code

```sh
touch ~/.claude.json
docker run --rm -ti \
  -v "$(pwd):/home/node/dev/${PWD##*/}" -w "/home/node/dev/${PWD##*/}" \
  -v ~/.claude:/home/node/.claude \
  -v ~/.claude.json:/home/node/.claude.json \
  nbr23/claudecode
```

Arguments after the image name are passed to `claude`, e.g. `nbr23/claudecode -p 'summarize this repo'`.

### OpenCode

```sh
docker run --rm -ti \
  -v "$(pwd):/home/node/dev/${PWD##*/}" -w "/home/node/dev/${PWD##*/}" \
  nbr23/claudecode:opencode
```

### Codex

```sh
docker run --rm -ti \
  -v "$(pwd):/home/node/dev/${PWD##*/}" -w "/home/node/dev/${PWD##*/}" \
  -v ~/.codex:/home/node/.codex \
  nbr23/claudecode:codex
```

### Antigravity CLI

```sh
docker run --rm -ti \
  -v "$(pwd):/home/node/dev/${PWD##*/}" -w "/home/node/dev/${PWD##*/}" \
  nbr23/antigravity
```

### All-in-one

`nbr23/claudecode:all` stays idle by default; start it detached and exec into it:

```sh
docker run -d --name agents \
  -v "$(pwd):/home/node/dev/${PWD##*/}" -w "/home/node/dev/${PWD##*/}" \
  nbr23/claudecode:all
docker exec -ti agents claude
```

## Building

Images are defined in `docker-bake.hcl`. The version variables have no defaults and must be set:

```sh
export CLAUDE_VERSION="$(jq -r '.devDependencies["@anthropic-ai/claude-code"]' package.json)"
export OPENCODE_VERSION="$(jq -r '.devDependencies["opencode-ai"]' package.json)"
export OPENCODE_GEMINI_AUTH_VERSION="$(jq -r '.devDependencies["opencode-gemini-auth"]' package.json)"
export CODEX_VERSION="$(jq -r '.dependencies["@openai/codex"]' package.json)"

docker buildx bake                # everything
docker buildx bake claudecode     # claude, opencode, codex, all
docker buildx bake antigravity    # nbr23/antigravity
```

To load a single target into the local image store, restrict it to one platform:

```sh
docker buildx bake claude --load --set '*.platform=linux/amd64'
```

## License

MIT
