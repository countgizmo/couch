package main

import "core:fmt"
import "core:time"
import "core:log"
import "core:strconv"
import "core:os"
import rl "vendor:raylib"

State :: struct {
  start: time.Time,
  session: [dynamic]Entry,
  keys_pressed: [dynamic]u8,
  exercises: i32,
  minutes: i32,
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
  text_size: f32 = 40
  position := rl.Vector2 {
    text_x,
    get_axis_y() - cast(f32) height - text_size,
  }

  rl.DrawTextEx(rl.GetFontDefault(), reps_text, position, text_size, 1, TEXT_COLOR)
}

render_total :: proc(state: ^State) {
  text: cstring

  // NOTE(evgheni): this is very program specific at the moment
  // Maybe I will make it more generic in the future if I ever need to.
  // Now it's targetted for the Maximorum KB program
  if state.exercises == 2 {
    even := false
    total1:i32
    total2:i32

    for e in state.session {
      if even {
        total2 += e.reps
        even = !even
      } else {
        total1 += e.reps
        even = !even
      }
    }

    text = fmt.ctprintf("%v / %v", total1, total2)
  } else if state.exercises == 1 {
    total: i32
    for e in state.session {
      total += e.reps
    }

    text = fmt.ctprintf("%v", total)
  } else {
    text = "WTF"
  }

  position := rl.Vector2 {
    get_axis_start_x(),
    SCREEN_PADDING,
  }

  rl.DrawTextEx(rl.GetFontDefault(), text, position, 44, 1, TEXT_COLOR)
}

render_session :: proc(state: ^State) {
  column_width := get_column_width(state.minutes, cast(i32)len(state.session))

  for &entry, idx in state.session {
    render_entry(idx, &entry, column_width)
  }

  render_total(state)
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

parse_args :: proc(state: ^State) {
  if len(os.args) == 1 {
    return
  }

  i := 1 // skipping the name of the command itself
  for i < len(os.args) {
    if os.args[i] == "-e" {
      i += 1
      exercises, _ := strconv.parse_int(os.args[i])
      state.exercises = cast(i32) exercises
    }

    if os.args[i] == "-m" {
      i += 1
      minutes, _ := strconv.parse_int(os.args[i])
      state.minutes = cast(i32) minutes
    }

    i +=1
  }
}

main :: proc() {
  context.logger = log.create_console_logger()

  state := State {
    start = time.now(),
    exercises = 1,
    minutes = 20,
  }

  parse_args(&state)

  rl.SetConfigFlags({
    .WINDOW_HIGHDPI,
    .WINDOW_MAXIMIZED,
    .WINDOW_RESIZABLE
  })

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
