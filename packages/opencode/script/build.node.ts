/**
 * OpenCode FreeBSD Build Script
 * 
 * This script builds OpenCode as a standalone Node.js executable using esbuild.
 * FreeBSD-only build - no Bun dependency for building.
 * 
 * Usage:
 *   node script/build.node.ts
 */

import * as esbuild from "esbuild"
import fs from "fs"
import path from "path"
import { fileURLToPath } from "url"
import os from "os"

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const dir = path.resolve(__dirname, "..")

// Version and channel - hardcoded for FreeBSD standalone build
const version = "1.14.30"
const channel = "stable"

// FreeBSD build target
const arch = os.arch() === "arm64" ? "arm64" : "x64"
const targetName = `opencode-freebsd-${arch}`

// Create dist directory
const distDir = path.join(dir, "dist", targetName, "bin")
await fs.promises.rm(path.join(dir, "dist"), { recursive: true, force: true })
await fs.promises.mkdir(distDir, { recursive: true })

console.log(`Building OpenCode for FreeBSD (${arch})...`)

// FreeBSD bunfs root path
const bunfsRoot = "/usr/local/lib/opencode/"

// Load migrations
const migrationDirs = (
  await fs.promises.readdir(path.join(dir, "migration"), {
    withFileTypes: true,
  })
)
  .filter((entry) => entry.isDirectory() && /^\d{14}/.test(entry.name))
  .map((entry) => entry.name)
  .sort()

const migrations = await Promise.all(
  migrationDirs.map(async (name) => {
    const file = path.join(dir, "migration", name, "migration.sql")
    const sql = await fs.promises.readFile(file, "utf-8")
    const match = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/.exec(name)
    const timestamp = match
      ? Date.UTC(
          Number(match[1]),
          Number(match[2]) - 1,
          Number(match[3]),
          Number(match[4]),
          Number(match[5]),
          Number(match[6]),
        )
      : 0
    return { sql, timestamp, name }
  })
)

console.log(`Loaded ${migrations.length} migrations`)

// Build with esbuild
await esbuild.build({
  entryPoints: [path.join(dir, "src/index.ts")],
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node18",
  outfile: path.join(distDir, "opencode"),
  external: ["node-gyp", "@opentui/core"],
  sourcemap: false,
  minify: false,
  define: {
    "OPENCODE_VERSION": `"${version}"`,
    "OPENCODE_MIGRATIONS": JSON.stringify(migrations),
    "OTUI_TREE_SITTER_WORKER_PATH": `"${bunfsRoot}"`,
    "OPENCODE_WORKER_PATH": `"./worker"`,
    "OPENCODE_CHANNEL": `"${channel}"`,
    "OPENCODE_LIBC": `""`,
  },
  plugins: [{
    name: "wasm-shim",
    setup(build) {
      build.onResolve({ filter: /\.wasm(\?.*)?$/ }, args => {
        return { path: args.path, external: true }
      })
      // Mark Bun-specific imports as external
      build.onResolve({ filter: /bun:/ }, args => {
        return { path: args.path, external: true }
      })
    },
  }],
})

// Write package.json for the built package
await fs.promises.writeFile(
  path.join(distDir, "package.json"),
  JSON.stringify({
    name: targetName,
    version,
    os: ["freebsd"],
    cpu: [arch],
  }, null, 2)
)

console.log(`\n✓ Built ${targetName} to dist/${targetName}/bin/opencode`)
console.log(`  Binary shebang: #!/usr/bin/env node`)
console.log(`  Run with: node dist/${targetName}/bin/opencode`)
