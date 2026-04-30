// Bun-specific migration adapter
import { migrate } from "drizzle-orm/bun-sqlite/migrator"
import { type SQLiteBunDatabase } from "drizzle-orm/bun-sqlite"

export type { SQLiteBunDatabase }
export { migrate }
