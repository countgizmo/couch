package main

import "core:fmt"
import "core:time"
import "core:log"
import rl "vendor:raylib"

Entry :: struct {
  reps: i32,
  t: time.Time,
}

TEXT_COLOR :rl.Color: {128, 128, 0, 255}
BG_COLOR :rl.Color: {0, 0, 128, 255}
SCREEN_PADDING :: 50

get_axis_start_x :: proc() -> f32 {
  return 0 + SCREEN_PADDING
}

get_axis_end_x :: proc() -> f32 {
  return cast(f32) rl.GetScreenWidth() - SCREEN_PADDING
}

get_axis_y :: proc() -> f32 {
  return cast(f32) rl.GetScreenHeight() - SCREEN_PADDING
}

get_column_width :: proc(chunks: i32) -> f32 {
  return (get_axis_end_x() - get_axis_start_x()) / cast(f32)chunks
}

render_axis :: proc() {
  line_start := rl.Vector2 {
    get_axis_start_x(),
    get_axis_y(),
  }

  line_end := rl.Vector2 {
    get_axis_end_x(),
    get_axis_y(),
  }

  rl.DrawLineEx( line_start, line_end, 5, TEXT_COLOR)
}

render_column :: proc(x: i32, height: i32) {
  position := rl.Vector2 {
    (get_axis_start_x() + cast(f32) x),
    get_axis_y() - cast(f32) height,
  }

  size := rl.Vector2 {
    get_column_width(30),
    cast(f32) height,
  }
  rl.DrawRectangleV(position, size, TEXT_COLOR)
}

render_entry :: proc(offset: i32, entry: ^Entry) {
  height := entry.reps * 50
  render_column(offset, height)

  reps_text := fmt.ctprintf("%v", entry.reps)
  text_x := (get_axis_start_x() + (get_column_width(30) / 2) + cast(f32) offset)
  position := rl.Vector2 {
    text_x,
    get_axis_y() - cast(f32) height - 20,
  }

  rl.DrawTextEx(rl.GetFontDefault(), reps_text, position, 20, 1, TEXT_COLOR)
}

render_session :: proc(session: ^[dynamic]^Entry) {
  width := get_column_width(30)
  padding: i32 = 10

  for entry, idx in session {
    offset := (cast(i32)(idx) * (padding + cast(i32)width))
    render_entry(offset, entry)
  }
}

main :: proc() {
  context.logger = log.create_console_logger()

  session: [dynamic]^Entry
  start := time.now()

  append(&session, &Entry{reps = 1, t = time.time_add(start, time.Minute + 1)})
  append(&session, &Entry{reps = 2, t = time.time_add(start, time.Minute + 2)})
  append(&session, &Entry{reps = 1, t = time.time_add(start, time.Minute + 3)})
  append(&session, &Entry{reps = 2, t = time.time_add(start, time.Minute + 4)})
  append(&session, &Entry{reps = 1, t = time.time_add(start, time.Minute + 5)})
  append(&session, &Entry{reps = 2, t = time.time_add(start, time.Minute + 6)})
  append(&session, &Entry{reps = 1, t = time.time_add(start, time.Minute + 7)})
  append(&session, &Entry{reps = 2, t = time.time_add(start, time.Minute + 8)})
  append(&session, &Entry{reps = 1, t = time.time_add(start, time.Minute + 9)})
  append(&session, &Entry{reps = 2, t = time.time_add(start, time.Minute + 10)})

  append(&session, &Entry{reps = 6, t = time.time_add(start, time.Minute + 1)})
  append(&session, &Entry{reps = 10, t = time.time_add(start, time.Minute + 2)})
  append(&session, &Entry{reps = 6, t = time.time_add(start, time.Minute + 3)})
  append(&session, &Entry{reps = 10, t = time.time_add(start, time.Minute + 4)})
  append(&session, &Entry{reps = 6, t = time.time_add(start, time.Minute + 5)})
  append(&session, &Entry{reps = 10, t = time.time_add(start, time.Minute + 6)})
  append(&session, &Entry{reps = 6, t = time.time_add(start, time.Minute + 7)})
  append(&session, &Entry{reps = 10, t = time.time_add(start, time.Minute + 8)})
  append(&session, &Entry{reps = 6, t = time.time_add(start, time.Minute + 9)})
  append(&session, &Entry{reps = 10, t = time.time_add(start, time.Minute + 10)})

  rl.SetConfigFlags({.WINDOW_HIGHDPI})

  rl.InitWindow(1200, 800, "Couch")

  defer rl.CloseWindow()

  rl.SetTargetFPS(30)
  rl.EnableEventWaiting()

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()

    rl.ClearBackground(BG_COLOR)
    render_axis()

    render_session(&session)

    rl.EndDrawing()
  }



}
