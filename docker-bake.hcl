variable "IMAGE" {
  default = "nbr23/claudecode"
}

variable "ANTIGRAVITY_IMAGE" {
  default = "nbr23/antigravity"
}

variable "CACHE_SUFFIX" {
  default = ""
}

variable "CLAUDE_VERSION" {}
variable "OPENCODE_VERSION" {}
variable "OPENCODE_GEMINI_AUTH_VERSION" {}
variable "CODEX_VERSION" {}

group "default" {
  targets = ["claudecode", "antigravity"]
}

group "claudecode" {
  targets = ["claude", "opencode", "codex"]
}

target "_tool" {
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=registry,ref=${IMAGE}:buildcache-claude${CACHE_SUFFIX}",
    "type=registry,ref=${IMAGE}:buildcache-opencode${CACHE_SUFFIX}",
    "type=registry,ref=${IMAGE}:buildcache-codex${CACHE_SUFFIX}",
  ]
}

target "claude" {
  inherits = ["_tool"]
  target   = "claude"
  args     = { CLAUDE_VERSION = CLAUDE_VERSION }
  tags     = ["${IMAGE}:latest", "${IMAGE}:claude", "${IMAGE}:claude-code-${CLAUDE_VERSION}"]
  cache-to = ["type=registry,ref=${IMAGE}:buildcache-claude${CACHE_SUFFIX},mode=max"]
}

target "opencode" {
  inherits = ["_tool"]
  target   = "opencode"
  args = {
    OPENCODE_VERSION             = OPENCODE_VERSION
    OPENCODE_GEMINI_AUTH_VERSION = OPENCODE_GEMINI_AUTH_VERSION
  }
  tags     = ["${IMAGE}:opencode", "${IMAGE}:opencode-${OPENCODE_VERSION}"]
  cache-to = ["type=registry,ref=${IMAGE}:buildcache-opencode${CACHE_SUFFIX},mode=max"]
}

target "codex" {
  inherits = ["_tool"]
  target   = "codex"
  args     = { CODEX_VERSION = CODEX_VERSION }
  tags     = ["${IMAGE}:codex", "${IMAGE}:codex-${CODEX_VERSION}"]
  cache-to = ["type=registry,ref=${IMAGE}:buildcache-codex${CACHE_SUFFIX},mode=max"]
}

target "antigravity" {
  context    = "."
  dockerfile = "Dockerfile.antigravity"
  platforms  = ["linux/amd64", "linux/arm64"]
  tags       = ["${ANTIGRAVITY_IMAGE}:latest"]
  cache-from = ["type=registry,ref=${ANTIGRAVITY_IMAGE}:buildcache${CACHE_SUFFIX}"]
  cache-to   = ["type=registry,ref=${ANTIGRAVITY_IMAGE}:buildcache${CACHE_SUFFIX},mode=max"]
}
