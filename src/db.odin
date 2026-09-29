package main

import "core:c"
import "core:fmt"
import "core:strings"
import "core:log"
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

create_table :: proc(db: ^DB, create_table_query: cstring) -> bool {
  create_table_stmt: ^Stmt
  result := sqlite3_prepare_v2(db, create_table_query, -1, &create_table_stmt, nil)
  defer sqlite3_finalize(create_table_stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return true
  }

  result = sqlite3_step(create_table_stmt)

  if result != .done {
    log.error("Failed to create the table", result)
    return false
  }

  return true
}

create_exercises_table :: proc(db: ^DB) -> bool {
  sql: cstring = "CREATE TABLE IF NOT EXISTS exercise (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE)"
  return create_table(db, sql)
}

exercise_names := []string {
  "KB Snatch",
  "KB Clean",
  "KB Front Squat",
  "KB Press",
}

insert_exercise :: proc(db: ^DB, name: string) -> bool {
  c_name := strings.clone_to_cstring(name)
  defer delete(c_name)
  insert_ex_stmt: ^Stmt

  insert_ex_sql: cstring = "INSERT OR IGNORE INTO exercise (name) VALUES (?)"
  result := sqlite3_prepare_v2(db, insert_ex_sql, -1, &insert_ex_stmt, nil)
  defer sqlite3_finalize(insert_ex_stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return false
  }

  result = sqlite3_bind_text(insert_ex_stmt, 1, c_name, -1, ~uintptr(0))

  if result != .ok {
    log.error("Failed to bind text", result)
    return false
  }

  result = sqlite3_step(insert_ex_stmt)

  if result != .done {
    log.error("Failed to insert a row", result)
    return false
  }

  return true
}

init_db :: proc(db: ^DB) {
  result := create_exercises_table(db)

  if !result {
    log.error("Couldn't create exercises table");
    return
  }

  for name in exercise_names {
    insert_exercise(db, name)
  }
}

get_all_exercise :: proc(state: ^State) -> bool {
  stmt: ^Stmt
  sql: cstring = "SELECT id, name from exercise"
  result := sqlite3_prepare_v2(state.db, sql, -1, &stmt, nil)
  defer sqlite3_finalize(stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return false
  }

  delete_exercises(state)
  loop: for {
    result = sqlite3_step(stmt)

    #partial switch result {
      case .row: {
        id := sqlite3_column_int64(stmt, 0)
        name := sqlite3_column_text(stmt, 1)
        append(&state.exercises, Exercise{ id, strings.clone(string(name)) })
      }
      case .done: {
        break loop
      }
      case: {
        log.error("Failed to read data from row", result)
        return false
      }
    }
  }

  return true
}

