// Node.js/FreeBSD SQLite implementation using node:sqlite
import { DatabaseSync } from "node:sqlite"

export type SqliteDatabase = DatabaseSync

export function openSqliteDb(path: string, options?: { readonly?: boolean }): DatabaseSync {
  return new DatabaseSync(path, options)
}
