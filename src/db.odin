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

Exec_Callback :: proc "c" (user: rawptr, n_cols: c.int, values: [^]cstring, names: [^]cstring) -> c.int

@(default_calling_convention="c")
foreign sqlite {
  sqlite3_libversion :: proc() -> cstring ---
  sqlite3_open_v2 :: proc(database: cstring, db: ^^DB, flags: c.int, vfs: cstring) -> rescode ---
  sqlite3_close :: proc(db: ^DB) -> rescode ---
  sqlite3_exec :: proc(db: ^DB, sql: cstring, callback: Exec_Callback, user: rawptr, errmsg: ^cstring) -> rescode ---
  sqlite3_free :: proc(p: rawptr) ---
  sqlite3_prepare_v2 :: proc(db: ^DB, sql: cstring, nbytes: c.int, stmt: ^^Stmt, tail: ^cstring) -> rescode ---
  sqlite3_finalize :: proc(stmt: ^Stmt) -> rescode ---
  sqlite3_step :: proc(stmt: ^Stmt) -> rescode ---
  sqlite3_bind_int64 :: proc(stmt: ^Stmt, index: c.int, num: i64) -> rescode ---
  sqlite3_bind_text :: proc(stmt: ^Stmt, index: c.int, text: [^]u8, bytes: c.int, destructor: uintptr) -> rescode ---
  sqlite3_column_int64 :: proc(stmt: ^Stmt, index: c.int) -> i64 ---
  sqlite3_column_text :: proc(stmt: ^Stmt, index: c.int) -> cstring ---
  sqlite3_errmsg :: proc(db: ^DB) -> cstring ---
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
  insert_ex_stmt: ^Stmt

  insert_ex_sql: cstring = "INSERT OR IGNORE INTO exercise (name) VALUES (?)"
  result := sqlite3_prepare_v2(db, insert_ex_sql, -1, &insert_ex_stmt, nil)
  defer sqlite3_finalize(insert_ex_stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return false
  }

  result = sqlite3_bind_text(insert_ex_stmt, 1, raw_data(name), i32(len(name)), ~uintptr(0))

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

insert_workout :: proc(db: ^DB, name: string, duration: i64) -> bool {
  insert_stmt: ^Stmt

  insert_sql: cstring = "INSERT OR IGNORE INTO workout (name, duration) VALUES (?, ?)"
  result := sqlite3_prepare_v2(db, insert_sql, -1, &insert_stmt, nil)
  defer sqlite3_finalize(insert_stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return false
  }

  result = sqlite3_bind_text(insert_stmt, 1, raw_data(name), i32(len(name)), ~uintptr(0))

  if result != .ok {
    log.error("Failed to bind name", result)
    return false
  }

  result = sqlite3_bind_int64(insert_stmt, 2, duration)

  if result != .ok {
    log.error("Failed to bind duratino", result)
    return false
  }


  result = sqlite3_step(insert_stmt)

  if result != .done {
    log.error("Failed to insert a row", result)
    return false
  }

  return true
}

create_workouts_table :: proc(db: ^DB) -> bool {
  sql: cstring = "CREATE TABLE IF NOT EXISTS workout (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, duration INTEGER NOT NULL)"
  return create_table(db, sql)
}

create_workout_exercise_table :: proc(db: ^DB) -> bool {
  sql: cstring = `
CREATE TABLE IF NOT EXISTS workout_exercise (
    id          INTEGER PRIMARY KEY,
    position    INTEGER NOT NULL,
    workout_id  INTEGER NOT NULL,
    exercise_id INTEGER NOT NULL,
    UNIQUE      (workout_id, position),
    FOREIGN KEY (workout_id)  REFERENCES workout(id)  ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercise(id)
);`
  return create_table(db, sql)
}

setup_db :: proc(db: ^DB) {
  errmsg: cstring
  if sqlite3_exec(db, "PRAGMA foreign_keys = ON;" , nil, nil, &errmsg) != rescode.ok {
    log.error("sqlite error:", errmsg)
    sqlite3_free(rawptr(errmsg))
  }
}

workouts := []Workout {
  { name = "KB Snatches", duration = 20 },
  { name = "KB Clean & Press + Front Squats", duration = 30 }
}

get_user_version :: proc(db: ^DB) -> (i64, bool) {
  stmt: ^Stmt
  sql: cstring = "PRAGMA user_version;"
  version: i64
  result := sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
  defer sqlite3_finalize(stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return version, false
  }

  result = sqlite3_step(stmt)

  if result == .row {
    version = sqlite3_column_int64(stmt, 0)
  } else {
    return version, false
  }

  return version, true
}

add_exercise_to_workout :: proc(db: ^DB, exercise_name: string, workout_name: string, position: int) -> bool {
  stmt: ^Stmt
  sql: cstring = `
      INSERT INTO workout_exercise (exercise_id, workout_id, position)
      VALUES (
        (SELECT id FROM exercise WHERE name = ?),
        (SELECT id FROM workout WHERE name = ?),
        ?
  );`

  result := sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
  defer sqlite3_finalize(stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result, sqlite3_errmsg(db))
    return false
  }

  result = sqlite3_bind_text(stmt, 1, raw_data(exercise_name), i32(len(exercise_name)), ~uintptr(0))
  if result != .ok {
    log.error("Failed to bind text", result, sqlite3_errmsg(db))
    return false
  }

  result = sqlite3_bind_text(stmt, 2, raw_data(workout_name), i32(len(workout_name)), ~uintptr(0))
  if result != .ok {
    log.error("Failed to bind text", result, sqlite3_errmsg(db))
    return false
  }

  result = sqlite3_bind_int64(stmt, 3, i64(position))
  if result != .ok {
    log.error("Failed to bind int", result, sqlite3_errmsg(db))
    return false
  }

  result = sqlite3_step(stmt)

  if result != .done {
    log.error("Failed to insert a row", result, sqlite3_errmsg(db))
    return false
  }

  return true
}

seed_data :: proc(db: ^DB) {
  user_version, ok := get_user_version(db)

  if !ok {
    log.error("Failed to get PRAGMA user_version")
    log.error("Not gonna seed the data")
    return
  }

  if user_version == 0 {
    add_exercise_to_workout(db, "KB Snatch", "KB Snatches", 1)
    add_exercise_to_workout(db, "KB Clean", "KB Clean & Press + Front Squats", 1)
    add_exercise_to_workout(db, "KB Press", "KB Clean & Press + Front Squats", 2)
    add_exercise_to_workout(db, "KB Front Squat", "KB Clean & Press + Front Squats", 3)
  }
}

init_db :: proc(db: ^DB) {
  setup_db(db)

  result := create_exercises_table(db)

  if !result {
    log.error("Couldn't create exercise table")
    return
  }

  for name in exercise_names {
    insert_exercise(db, name)
  }

  result = create_workouts_table(db)
  if !result {
    log.error("Couldn't create workout table")
    return
  }

  for workout in workouts {
    insert_workout(db, workout.name, workout.duration)
  }

  result = create_workout_exercise_table(db)
  if !result {
    log.error("Couldn't create workout_exercise table")
    return
  }

  seed_data(db)

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

get_all_workouts :: proc(state: ^State) -> bool {
  stmt: ^Stmt
  sql: cstring = "SELECT id, name, duration from workout"
  result := sqlite3_prepare_v2(state.db, sql, -1, &stmt, nil)
  defer sqlite3_finalize(stmt)

  if result != .ok {
    log.error("Failed to prepare statement", result)
    return false
  }

  delete_workouts(state)
  loop: for {
    result = sqlite3_step(stmt)

    #partial switch result {
      case .row: {
        id := sqlite3_column_int64(stmt, 0)
        name := sqlite3_column_text(stmt, 1)
        duration := sqlite3_column_int64(stmt, 2)
        append(&state.workouts, Workout{ id, strings.clone(string(name)), duration })
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
