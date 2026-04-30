/**
 * WASM shim for Node.js
 * This file provides stub WASM modules that tree-sitter can load
 * The actual WASM loading is handled by web-tree-sitter internally
 */

// These will be replaced with actual WASM buffers at runtime
export const treeSitterWasm = undefined as unknown as WebAssembly.Module
export const treeSitterBashWasm = undefined as unknown as WebAssembly.Module
export const treeSitterPowershellWasm = undefined as unknown as WebAssembly.Module
