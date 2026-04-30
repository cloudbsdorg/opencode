import { readFileSync } from "node:fs"

/**
 * Read all text from stdin.
 * Works cross-platform on Linux, macOS, FreeBSD, and Windows.
 * On Windows, uses process.stdin which handles the conversion automatically.
 * On Unix-like systems, reads from /dev/stdin which is available on all platforms.
 */
export async function readStdin(): Promise<string> {
  // Windows and some environments handle stdin differently
  if (process.platform === "win32") {
    return new Promise((resolve, reject) => {
      let data = ""
      process.stdin.setEncoding("utf8")
      process.stdin.on("data", (chunk) => (data += chunk))
      process.stdin.on("end", () => resolve(data))
      process.stdin.on("error", reject)
    })
  }

  // Unix-like systems (Linux, macOS, FreeBSD, etc.)
  // Using readFileSync with /dev/stdin is reliable across all Unix platforms
  try {
    return readFileSync("/dev/stdin", "utf8")
  } catch {
    // Fallback to reading from fd 0
    return readFileSync(0, "utf8")
  }
}
