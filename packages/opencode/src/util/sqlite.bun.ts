// Bun-specific SQLite implementation using bun:sqlite
import { Database } from "bun:sqlite"

export type SqliteDatabase = Database

export function openSqliteDb(path: string, options?: { readonly?: boolean }): Database {
  return new Database(path, options)
}
