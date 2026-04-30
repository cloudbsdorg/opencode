/**
 * WASM loader utilities for Node.js compatibility
 * Replaces Bun's `import("foo.wasm", { with: { type: "wasm" } })` syntax
 */

import fs from "fs"
import path from "path"
import { fileURLToPath } from "url"

/**
 * Load a WASM file from a URL or file path
 * Handles both Node.js and Bun environments
 */
export async function loadWasm(
  source: string | URL,
  baseUrl?: string
): Promise<WebAssembly.Module> {
  let buffer: ArrayBuffer

  if (source instanceof URL) {
    if (source.protocol === "file:") {
      buffer = await fs.promises.readFile(source)
    } else {
      const response = await fetch(source)
      buffer = await response.arrayBuffer()
    }
  } else if (source.startsWith("file://")) {
    const filePath = fileURLToPath(source)
    buffer = await fs.promises.readFile(filePath)
  } else if (source.startsWith("/") || source.startsWith(".")) {
    buffer = await fs.promises.readFile(source)
  } else if (baseUrl) {
    const filePath = path.resolve(baseUrl, source)
    buffer = await fs.promises.readFile(filePath)
  } else {
    // Try to resolve as node_modules path
    const resolved = require.resolve(source)
    buffer = await fs.promises.readFile(resolved)
  }

  return new WebAssembly.Module(buffer)
}

/**
 * Load a WASM file and return its exports as a default export object
 * Compatible with Bun's WASM import syntax
 */
export async function loadWasmAsDefault(
  source: string | URL,
  baseUrl?: string
): Promise<{ default: WebAssembly.Module }> {
  const module = await loadWasm(source, baseUrl)
  return { default: module }
}

/**
 * Resolve WASM path for tree-sitter
 * Converts a WASM Module to a temporary file path for tree-sitter's locateFile
 */
export function resolveWasmModulePath(wasmModule: WebAssembly.Module): string {
  const tmpDir = process.env.TEMP || process.env.TMP || "/tmp"
  const wasmFile = path.join(tmpDir, `tree-sitter-wasm-${Date.now()}.wasm`)
  
  const buffer = WebAssembly.Module.exportding(wasmModule)
  fs.writeFileSync(wasmFile, Buffer.from(buffer))
  
  return wasmFile
}
