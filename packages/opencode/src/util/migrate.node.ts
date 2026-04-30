// Node.js/FreeBSD migration adapter
import { migrate } from "drizzle-orm/node-sqlite/migrator"
import { type NodeSQLiteDatabase } from "drizzle-orm/node-sqlite"

export type { NodeSQLiteDatabase as SQLiteBunDatabase }
export { migrate }
