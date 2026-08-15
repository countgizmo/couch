package probesqlite

import "core:fmt"
foreign import sqlite "system:sqlite3"

@(default_calling_convention="c")
foreign sqlite {
  sqlite3_libversion :: proc() -> cstring ---
}

main :: proc() {
  version := sqlite3_libversion()
  fmt.println("Version =", version)
}
