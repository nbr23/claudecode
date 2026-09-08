variable "IMAGE" {
  default = "nbr23/claudecode"
}

variable "CLAUDE_VERSION" {}
variable "OPENCODE_VERSION" {}
variable "OPENCODE_GEMINI_AUTH_VERSION" {}
variable "CODEX_VERSION" {}

group "default" {
  targets = ["claude", "opencode", "codex"]
}

target "_tool" {
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=registry,ref=${IMAGE}:buildcache-claude",
    "type=registry,ref=${IMAGE}:buildcache-opencode",
    "type=registry,ref=${IMAGE}:buildcache-codex",
  ]
}

target "claude" {
  inherits = ["_tool"]
  target   = "claude"
  args     = { CLAUDE_VERSION = CLAUDE_VERSION }
  tags     = ["${IMAGE}:latest", "${IMAGE}:claude", "${IMAGE}:claude-code-${CLAUDE_VERSION}"]
  cache-to = ["type=registry,ref=${IMAGE}:buildcache-claude,mode=max"]
}

target "opencode" {
  inherits = ["_tool"]
  target   = "opencode"
  args = {
    OPENCODE_VERSION             = OPENCODE_VERSION
    OPENCODE_GEMINI_AUTH_VERSION = OPENCODE_GEMINI_AUTH_VERSION
  }
  tags     = ["${IMAGE}:opencode", "${IMAGE}:opencode-${OPENCODE_VERSION}"]
  cache-to = ["type=registry,ref=${IMAGE}:buildcache-opencode,mode=max"]
}

target "codex" {
  inherits = ["_tool"]
  target   = "codex"
  args     = { CODEX_VERSION = CODEX_VERSION }
  tags     = ["${IMAGE}:codex", "${IMAGE}:codex-${CODEX_VERSION}"]
  cache-to = ["type=registry,ref=${IMAGE}:buildcache-codex,mode=max"]
}
