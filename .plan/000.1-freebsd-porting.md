# OpenCode FreeBSD Porting Plan

**Author:** Mark LaPointe  
**Date:** 2026-04-30  
**Repository:** https://github.com/cloudbsdorg/freebsd-src-build-emulation  
**Branch:** `dev`

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Current Architecture Analysis](#2-current-architecture-analysis)
- [3. Proposed Changes](#3-proposed-changes)
- [4. Implementation Tasks](#4-implementation-tasks)
- [5. Testing Strategy](#5-testing-strategy)

---

## 1. Executive Summary

This document outlines the plan to port opencode from Bun runtime to Node.js runtime with FreeBSD support. The goal is to leverage FreeBSD's native capabilities while maintaining cross-platform compatibility with Linux and macOS.

**Primary Changes:**
1. Remove Bun runtime dependency for build process
2. Add FreeBSD platform support
3. Replace `bun-pty` with `node-pty` for FreeBSD
4. Update conditional imports to support FreeBSD conditions

---

## 2. Current Architecture Analysis

### 2.1 Current Conditional Imports

The project uses Node.js conditional imports in `packages/opencode/package.json`:

```json
{
  "#pty": {
    "bun": "./src/pty/pty.bun.ts",
    "node": "./src/pty/pty.node.ts",
    "default": "./src/pty/pty.bun.ts"
  },
  "#hono": {
    "bun": "./src/server/adapter.bun.ts",
    "node": "./src/server/adapter.node.ts",
    "default": "./src/server/adapter.bun.ts"
  },
  "#db": {
    "bun": "./src/storage/db.bun.ts",
    "node": "./src/storage/db.node.ts",
    "default": "./src/storage/db.bun.ts"
  }
}
```

### 2.2 Bun-Specific APIs Used

| Location | API | Alternative |
|----------|-----|-------------|
| `pty.bun.ts` | `bun-pty` | `node-pty` |
| `adapter.bun.ts` | `Bun.serve()` | `@hono/node-server` |
| Various files | `Bun.file()` | `fs.promises` or `node:fs` |
| `script/build.ts` | Shebang `bun` | `node` |
| Build script | `Bun.build()` | `esbuild` API |
| Tests | `bun test` | `node --test` or `bun` (keep for now) |

### 2.3 Build Targets

Current targets in `script/build.ts`:
- Linux (x64, arm64, musl, baseline)
- Darwin (x64, arm64, baseline)
- Windows (x64, arm64, baseline)

---

## 3. Proposed Changes

### 3.1 Package.json Updates

Add `freebsd` condition to all conditional imports:

```json
{
  "#pty": {
    "bun": "./src/pty/pty.bun.ts",
    "node": "./src/pty/pty.node.ts",
    "freebsd": "./src/pty/pty.freebsd.ts",
    "default": "./src/pty/pty.bun.ts"
  }
}
```

### 3.2 New FreeBSD PTY Implementation

Create `src/pty/pty.freebsd.ts` using `node-pty` (which has FreeBSD support via prebuilds).

### 3.3 Build Script Updates

Add FreeBSD targets:
- `freebsd-x64`
- `freebsd-arm64`

---

## 4. Implementation Tasks

### Task 0: Project Setup ✓
- [x] Create `AGENTS_START_HERE.md`
- [x] Create `PLAN.md`

### Task 1: Package.json Updates
- [ ] Add `freebsd` condition to `#pty` imports
- [ ] Add `freebsd` condition to `#hono` imports  
- [ ] Add `freebsd` condition to `#db` imports
- [ ] Add `@lydell/node-pty-freebsd-*` prebuild dependencies (if needed)

### Task 2: FreeBSD PTY Implementation
- [ ] Create `src/pty/pty.freebsd.ts` using `node-pty`
- [ ] Verify `node-pty` has FreeBSD prebuilds
- [ ] Test PTY functionality on FreeBSD

### Task 3: FreeBSD Database Implementation  
- [ ] Create `src/storage/db.freebsd.ts` using `better-sqlite3` or node driver
- [ ] Verify database operations work

### Task 4: FreeBSD Server Adapter
- [ ] Use existing `adapter.node.ts` for FreeBSD (same as Linux)
- [ ] Verify WebSocket and HTTP server work

### Task 5: Build Script Updates
- [ ] Add FreeBSD to build targets in `script/build.ts`
- [ ] Add FreeBSD prebuild install commands
- [ ] Update esbuild configuration if needed

### Task 6: Testing
- [ ] Test build on FreeBSD
- [ ] Test runtime on FreeBSD
- [ ] Verify all features work

---

## 5. Testing Strategy

### 5.1 Build Testing
1. Run build script on FreeBSD
2. Verify all platform-specific binaries are created
3. Check for missing native dependencies

### 5.2 Runtime Testing
1. Launch opencode on FreeBSD
2. Test PTY/shell functionality
3. Test server/client features
4. Test database operations

### 5.3 CI/CD
- Add FreeBSD CI runner (Cirrus-CI or GitHub Actions with FreeBSD)
- Test on every PR

---

## Appendix A: References

- [node-pty Repository](https://github.com/lydell/node-pty)
- [FreeBSD node-pty Prebuilds](https://github.com/lydell/node-pty-prebuilt)
- [Bun to Node.js Migration Guide](https://bun.sh/docs/runtime/nodejs-apis)
- [CloudBSD freebsd-src-oci](https://github.com/cloudbsdorg/freebsd-src-oci)

---

## Appendix B: Success Criteria

1. ✅ OpenCode builds successfully on FreeBSD (x64 and arm64)
2. ✅ PTY/shell functionality works on FreeBSD
3. ✅ WebSocket and HTTP server work on FreeBSD
4. ✅ Database operations work on FreeBSD
5. ✅ All existing tests pass on FreeBSD
6. ✅ Cross-platform compatibility maintained (Linux, macOS, Windows)
