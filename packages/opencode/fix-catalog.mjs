#!/usr/bin/env node
// Fix catalog: references in package.json for npm compatibility

import { readFileSync, writeFileSync } from "fs"
import { platform, arch } from "process"
import { resolve, dirname } from "path"
import { fileURLToPath } from "url"

const __dirname = dirname(fileURLToPath(import.meta.url))
const rootDir = resolve(__dirname, "../..")

// Load catalog from root package.json
let catalog = {}
try {
  const rootPkg = JSON.parse(readFileSync(resolve(rootDir, "package.json"), "utf-8"))
  if (rootPkg.workspaces?.catalog) {
    catalog = rootPkg.workspaces.catalog
  }
} catch (e) {
  console.error("Warning: Could not load root package.json catalog:", e.message)
}

// Default catalog values (fallback if root package.json not found)
const defaultCatalog = {
  "@effect/opentelemetry": "4.0.0-beta.57",
  "@effect/platform-node": "4.0.0-beta.57",
  "@opentui/core": "0.1.105",
  "@opentui/solid": "0.1.105",
  "ulid": "3.0.1",
  "drizzle-orm": "1.0.0-beta.19-d95b7a4",
  "effect": "4.0.0-beta.57",
  "ai": "6.0.168",
  "hono": "4.10.7",
  "semver": "7.7.4",
  "typescript": "5.8.2",
  "zod": "4.1.8",
  "@types/bun": "1.3.12",
  "@types/node": "22.13.9",
  "@types/luxon": "3.7.1",
  "@types/semver": "7.7.1",
  "@typescript/native-preview": "7.0.0-dev.20251207.1",
}

// Merge catalogs
catalog = { ...defaultCatalog, ...catalog }

const pkg = JSON.parse(readFileSync(resolve(__dirname, "package.json"), "utf-8"))

// Function to resolve catalog: references in dependency values
function resolveCatalog(value) {
  if (value === "catalog:") {
    return null // Remove unresolved catalog: references
  }
  if (typeof value === "string" && value.startsWith("catalog:")) {
    const pkgName = value.slice(8) // Remove "catalog:" prefix
    return catalog[pkgName] || null
  }
  return value
}

// Process all dependency sections
const sections = ["dependencies", "devDependencies", "optionalDependencies", "overrides"]
for (const section of sections) {
  if (!pkg[section]) continue
  
  for (const [key, val] of Object.entries(pkg[section])) {
    if (typeof val === "string") {
      const resolved = resolveCatalog(val)
      if (resolved === null) {
        delete pkg[section][key]
      } else {
        pkg[section][key] = resolved
      }
    } else if (typeof val === "object" && val !== null) {
      // Handle nested overrides
      for (const [nestedKey, nestedVal] of Object.entries(val)) {
        if (typeof nestedVal === "string") {
          const resolved = resolveCatalog(nestedVal)
          if (resolved === null) {
            delete pkg[section][key][nestedKey]
          } else {
            pkg[section][key][nestedKey] = resolved
          }
        }
      }
    }
  }
  
  // Clean up empty sections
  if (Object.keys(pkg[section]).length === 0) {
    delete pkg[section]
  }
}

// Platform-specific packages to remove
const platformOnly = [
  '@parcel/watcher-darwin-arm64',
  '@parcel/watcher-darwin-x64',
  '@parcel/watcher-linux-arm64-glibc',
  '@parcel/watcher-linux-arm64-musl',
  '@parcel/watcher-linux-x64-musl',
  '@parcel/watcher-win32-arm64',
  '@parcel/watcher-win32-x64',
]

for (const key of platformOnly) {
  delete pkg.devDependencies?.[key]
  delete pkg.dependencies?.[key]
  delete pkg.optionalDependencies?.[key]
}

// FreeBSD-specific and Linux compatibility layer
if (platform === "freebsd" || platform === "linux") {
  delete pkg.dependencies?.["@parcel/watcher"]
  delete pkg.devDependencies?.["@parcel/watcher"]
  delete pkg.optionalDependencies?.["@parcel/watcher"]
}

// Remove workspace packages that we can't resolve
const workspacePkgs = [
  "@opencode-ai/core",
  "@opencode-ai/script",
  "@opencode-ai/sdk",
  "@opencode-ai/plugin",
]

for (const key of workspacePkgs) {
  delete pkg.dependencies?.[key]
  delete pkg.devDependencies?.[key]
}

// Clean up overrides
if (pkg.overrides) {
  for (const [key, val] of Object.entries(pkg.overrides)) {
    if (typeof val === "string" && !val) {
      delete pkg.overrides[key]
    }
  }
  if (Object.keys(pkg.overrides).length === 0) {
    delete pkg.overrides
  }
}

// Remove scripts that use bun
if (pkg.scripts) {
  delete pkg.scripts.prepare
  delete pkg.scripts.test
  delete pkg.scripts.dev
  delete pkg.scripts["dev:temporary"]
  delete pkg.scripts.db
}

writeFileSync(resolve(__dirname, "package-node.json"), JSON.stringify(pkg, null, 2))
console.log("Created package-node.json")
console.log(`Dependencies: ${Object.keys(pkg.dependencies || {}).length}`)
console.log(`DevDependencies: ${Object.keys(pkg.devDependencies || {}).length}`)
