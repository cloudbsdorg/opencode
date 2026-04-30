# OpenCode FreeBSD Build Agent — Start Here

## Overview

This project is being ported to run natively on FreeBSD. The goal is to remove the Bun runtime dependency and make opencode work natively on FreeBSD systems.

## Project Context

- **Main Project**: https://github.com/cloudbsdorg/freebsd-src-oci
- **Build Emulation Project**: https://github.com/cloudbsdorg/freebsd-src-build-emulation (this repo)

The opencode project follows the CloudBSD workflow patterns established in the parent `freebsd-src-oci` repository. See the agent workflow documentation there: https://github.com/cloudbsdorg/freebsd-src-oci/blob/main/.plan/000.1-Agent-Workflow.md

## Current Status

- **Phase**: Implementation complete, testing & CI pending
- **Goal**: Remove Bun runtime dependency, add FreeBSD support
- **Completed**: All core cross-platform fixes implemented
- **Pending**: FreeBSD CI setup and end-to-end testing

## Key Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent guidelines and style guide |
| `.plan/` | Planning documents directory |
| `packages/opencode/package.json` | Main package with conditional exports |
| `packages/opencode/src/pty/` | PTY implementations (bun/node) |
| `packages/opencode/src/server/` | Server adapters (bun/node) |
| `packages/opencode/script/build.ts` | Build script with platform targets |
| `packages/opencode/Makefile.freebsd` | FreeBSD Makefile with auto-detection |
| `packages/opencode/install.sh` | Installation script with auto-detection |

## Installation

Both the Makefile and install script auto-detect the best installation location and configure PATH:

```bash
# Using Makefile
make install-auto          # Auto-detect (system if root, user-local otherwise)
make install              # Default: /usr/local
make install-user         # ~/.local
make configure-path       # Configure PATH in shell profile

# Using install script
./install.sh              # Auto-detect
./install.sh --system     # System-wide
./install.sh --user       # User-local
```

The scripts:
1. Create `~/.local` directories automatically if they don't exist
2. Detect user's shell (bash, zsh, fish, tcsh/csh)
3. Check shell profiles for existing PATH entries
4. Add `~/.local/bin` to the appropriate profile if needed
5. Provide shell-specific reload instructions

## Quick Start

1. Review `AGENTS.md` for coding standards
2. Review `PLAN.md` for current task list
3. Pick an unclaimed task from the plan
4. Implement and test
5. Commit with message starting with task number

## Important Notes

- The default branch is `dev` (not `main`)
- Use parallel tool calls when applicable
- Prefer Node.js APIs over Bun-specific ones
- node-pty requires FreeBSD prebuilds (check `@lydell/node-pty`)

## Build Targets (Goal)

Currently supported:
- Linux (x64, arm64, musl, baseline)
- Darwin/macOS (x64, arm64)
- Windows (x64, arm64)

Target to add:
- FreeBSD (x64, arm64)

## Related Repositories

| Repository | Purpose |
|------------|---------|
| https://github.com/cloudbsdorg/freebsd-src-oci | FreeBSD OCI tooling |
| https://github.com/cloudbsdorg/freebsd-src-build-emulation | This project |
