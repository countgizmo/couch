package main

import "core:fmt"
import "core:time"
import "core:log"
import "core:strconv"
import rl "vendor:raylib"

State :: struct {
  start: time.Time,
  session: [dynamic]Entry,
  keys_pressed: [dynamic]u8,
  current_reps: i32,
}

Entry :: struct {
  reps: i32,
  t: time.Time,
}

TEXT_COLOR :rl.Color: {128, 128, 0, 255}
BG_COLOR :rl.Color: {0, 0, 128, 255}
SCREEN_PADDING :: 50
COLUMN_PADDING: f32 = 10


get_axis_start_x :: proc() -> f32 {
  return 0 + SCREEN_PADDING
}

get_axis_end_x :: proc() -> f32 {
  return cast(f32) rl.GetScreenWidth() - SCREEN_PADDING
}

get_axis_y :: proc() -> f32 {
  return cast(f32) rl.GetScreenHeight() - SCREEN_PADDING
}

get_column_width :: proc(chunks: i32, count: i32) -> f32 {
  line_width := get_axis_end_x() - get_axis_start_x()
  chunks_based := line_width / cast(f32) chunks

  total_width_needed := (chunks_based + COLUMN_PADDING) * cast(f32)count - COLUMN_PADDING

  if total_width_needed > line_width {
    total_padding := COLUMN_PADDING * cast(f32)(count - 1)
    available_width := line_width - total_padding
    dynamic_width := available_width / cast(f32)count

    return dynamic_width
  }

  return chunks_based
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

render_entry :: proc(idx: int, entry: ^Entry, width: f32) {
  height := entry.reps * 50
  offset := cast(f32)(idx) * (COLUMN_PADDING + width)

  rl.DrawRectangleRec(
    rl.Rectangle {
      x = (get_axis_start_x() + offset),
      y = get_axis_y() - cast(f32) height,
      width = width,
      height = cast(f32) height,
    },
    TEXT_COLOR)

  reps_text := fmt.ctprintf("%v", entry.reps)
  text_x := (get_axis_start_x() + (width / 2) + offset)
  position := rl.Vector2 {
    text_x,
    get_axis_y() - cast(f32) height - 20,
  }

  rl.DrawTextEx(rl.GetFontDefault(), reps_text, position, 20, 1, TEXT_COLOR)
}

render_session :: proc(state: ^State) {
  column_width := get_column_width(30, cast(i32)len(state.session))

  for &entry, idx in state.session {
    render_entry(idx, &entry, column_width)
  }
}

convert_to_number :: proc(ascii_digits: [dynamic]u8) -> i32 {
    result: i32 = 0
    for digit_byte in ascii_digits {
        if digit_byte >= '0' && digit_byte <= '9' {
            digit_value := i32(digit_byte - 48)  //  ASCII for digits are between 48 and 57
            result = result * 10 + digit_value
        }
    }
    return result
}

process_input :: proc(state: ^State) {
  key := rl.GetKeyPressed()
  #partial switch key {
  case .ZERO..=.NINE:
    append(&state.keys_pressed, cast(u8)key)
  case .ENTER:
    reps_num := convert_to_number(state.keys_pressed)
    append(&state.session, Entry{reps = reps_num, t = time.now()})
    clear(&state.keys_pressed)
  }
}

main :: proc() {
  context.logger = log.create_console_logger()

  state := State {
    start = time.now(),
  }

  append(&state.session, Entry{reps = 1, t = time.time_add(state.start, time.Minute + 1)})
  append(&state.session, Entry{reps = 2, t = time.time_add(state.start, time.Minute + 2)})
  append(&state.session, Entry{reps = 1, t = time.time_add(state.start, time.Minute + 3)})
  append(&state.session, Entry{reps = 2, t = time.time_add(state.start, time.Minute + 4)})
  append(&state.session, Entry{reps = 1, t = time.time_add(state.start, time.Minute + 5)})
  append(&state.session, Entry{reps = 2, t = time.time_add(state.start, time.Minute + 6)})
  append(&state.session, Entry{reps = 1, t = time.time_add(state.start, time.Minute + 7)})
  append(&state.session, Entry{reps = 2, t = time.time_add(state.start, time.Minute + 8)})
  append(&state.session, Entry{reps = 1, t = time.time_add(state.start, time.Minute + 9)})
  append(&state.session, Entry{reps = 2, t = time.time_add(state.start, time.Minute + 10)})

  append(&state.session, Entry{reps = 6, t = time.time_add(state.start, time.Minute + 1)})
  append(&state.session, Entry{reps = 10, t = time.time_add(state.start, time.Minute + 2)})
  append(&state.session, Entry{reps = 6, t = time.time_add(state.start, time.Minute + 3)})
  append(&state.session, Entry{reps = 10, t = time.time_add(state.start, time.Minute + 4)})
  append(&state.session, Entry{reps = 6, t = time.time_add(state.start, time.Minute + 5)})
  append(&state.session, Entry{reps = 10, t = time.time_add(state.start, time.Minute + 6)})
  append(&state.session, Entry{reps = 6, t = time.time_add(state.start, time.Minute + 7)})
  append(&state.session, Entry{reps = 10, t = time.time_add(state.start, time.Minute + 8)})
  append(&state.session, Entry{reps = 6, t = time.time_add(state.start, time.Minute + 9)})
  append(&state.session, Entry{reps = 10, t = time.time_add(state.start, time.Minute + 10)})

  rl.SetConfigFlags({.WINDOW_HIGHDPI})

  rl.InitWindow(1200, 800, "Couch")

  defer rl.CloseWindow()

  rl.SetTargetFPS(30)
  rl.EnableEventWaiting()

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()

    rl.ClearBackground(BG_COLOR)

    process_input(&state)
    render_axis()
    render_session(&state)

    rl.EndDrawing()
  }



}
