package probesqlite

import "core:c"
import "core:fmt"
foreign import sqlite "system:sqlite3"

DB :: struct {}
Stmt :: struct {}

rescode :: enum c.int {
  ok = 0,
  error = 1,
  misuse = 21,
  row = 100,
  done = 101,
}

OPEN_READWRITE :: 0x2
OPEN_CREATE    :: 0x4

@(default_calling_convention="c")
foreign sqlite {
  sqlite3_libversion :: proc() -> cstring ---
  sqlite3_open_v2 :: proc(database: cstring, db: ^^DB, flags: c.int, vfs: cstring) -> rescode ---
  sqlite3_close :: proc(db: ^DB) -> rescode ---
  sqlite3_prepare_v2 :: proc(db: ^DB, sql: cstring, nbytes: c.int, stmt: ^^Stmt, tail: ^cstring) -> rescode ---
  sqlite3_finalize :: proc(stmt: ^Stmt) -> rescode ---
  sqlite3_step :: proc(stmt: ^Stmt) -> rescode ---
  sqlite3_bind_int64 :: proc(stmt: ^Stmt, index: c.int, num: i64) -> rescode ---
  sqlite3_bind_text :: proc(stmt: ^Stmt, index: c.int, text: cstring, bytes: c.int, destructor: uintptr) -> rescode ---
  sqlite3_column_int64 :: proc(stmt: ^Stmt, index: c.int) -> i64 ---
  sqlite3_column_text :: proc(stmt: ^Stmt, index: c.int) -> cstring ---
}

create_some_tables :: proc(db: ^DB) -> bool {
  create_table_stmt: ^Stmt
  create_table_sql: cstring = "CREATE TABLE IF NOT EXISTS exercise (id INTEGER PRIMARY KEY, name TEXT NOT NULL)"
  result := sqlite3_prepare_v2(db, create_table_sql, -1, &create_table_stmt, nil)
  defer sqlite3_finalize(create_table_stmt)

  if result != .ok {
    fmt.println("Error: failed to prepare statement", result)
    return true
  }

  result = sqlite3_step(create_table_stmt)

  if result != .done {
    fmt.println("Error: failed to create the table", result)
    return false
  }

  fmt.println("Create Table result =", result)
  return true
}

populate_db_with_bullshit :: proc(db: ^DB) -> bool {
  insert_ex_stmt: ^Stmt
  insert_ex_sql: cstring = "INSERT INTO exercise (name) VALUES (?)"
  result := sqlite3_prepare_v2(db, insert_ex_sql, -1, &insert_ex_stmt, nil)
  defer sqlite3_finalize(insert_ex_stmt)

  if result != .ok {
    fmt.println("Error: failed to prepare statement", result)
    return false
  }

  result = sqlite3_bind_text(insert_ex_stmt, 1, "KB Snatch", -1, ~uintptr(0))

  if result != .ok {
    fmt.println("Error: failed to bind text", result)
    return false
  }

  result = sqlite3_step(insert_ex_stmt)

  if result != .done {
    fmt.println("Error: failed to insert a row", result)
    return false
  }

  fmt.println("Insert exercise result =", result)
  return true
}

read_some_bullshit :: proc(db: ^DB) -> bool {
  stmt: ^Stmt
  sql: cstring = "SELECT id, name from exercise"
  result := sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
  defer sqlite3_finalize(stmt)

  if result != .ok {
    fmt.println("Error: failed to prepare statement", result)
    return false
  }

  loop: for {
    result = sqlite3_step(stmt)

    #partial switch result {
      case .row: {
        id := sqlite3_column_int64(stmt, 0)
        name := sqlite3_column_text(stmt, 1)
        fmt.printfln("id = %v, name = %v", id, name)
      }
      case .done: {
        break loop
      }
      case: {
        fmt.println("Error: failed to read data from row", result)
        return false
      }
    }
  }

  return true
}

main :: proc() {
  version := sqlite3_libversion()
  fmt.println("Version =", version)

  db: ^DB
  result: rescode
  flags: c.int = OPEN_READWRITE | OPEN_CREATE

  result = sqlite3_open_v2("test.db", &db, flags, nil)
  defer sqlite3_close(db)
  fmt.println("Open DB result =", result)

  if result != .ok {
    fmt.println("Error: couldn't open the DB", result)
    return
  }

  create_some_tables(db)
  // populate_db_with_bullshit(db)
  read_some_bullshit(db)
}
