// Windows-specific console handling - no-op on non-Windows platforms
// bun:ffi is not available on Node.js, so we provide stubs

export function win32DisableProcessedInput() {
  // No-op on non-Windows platforms
}

export function win32FlushInputBuffer() {
  // No-op on non-Windows platforms
}

export function win32InstallCtrlCGuard() {
  // No-op on non-Windows platforms
  return undefined
}
