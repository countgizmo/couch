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
  inputting: bool,
  analytics: bool,
}

Entry :: struct {
  reps: i32,
  t: time.Time,
}

TEXT_COLOR :rl.Color: {128, 128, 0, 255}
BG_COLOR :rl.Color: {0, 0, 128, 255}
TEXT_COLOR_FADED :rl.Color: {128, 128, 0, 150}
SCREEN_PADDING :: 50
COLUMN_MULTIPLIER :: 50
COLUMN_PADDING: f32 = 10
ANALYTICS_COLOR :rl.Color: {128, 0, 0, 255}

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
  chunks_based := line_width / cast(f32)chunks

  total_width_needed := (chunks_based + COLUMN_PADDING) * cast(f32)count - COLUMN_PADDING

  if total_width_needed > line_width {
    total_padding := COLUMN_PADDING * cast(f32)(count - 1)
    available_width := line_width - total_padding
    dynamic_width := available_width / cast(f32)count

    return dynamic_width
  }

  return chunks_based
}

render_analytics :: proc(state: ^State) {

  // Axis

  x_axis_start := rl.Vector2 {
    get_axis_start_x(),
    get_axis_y(),
  }

  x_axis_end := rl.Vector2 {
    get_axis_end_x(),
    get_axis_y(),
  }

  rl.DrawLineEx( x_axis_start, x_axis_end, 5, ANALYTICS_COLOR)

  y_axis_start := rl.Vector2 {
    get_axis_start_x(),
    get_axis_y(),
  }

  y_end_x := get_axis_start_x()
  y_end_y: f32 = 0 + SCREEN_PADDING

  y_axis_end := rl.Vector2 { y_end_x, y_end_y }

  y_axis_height := y_axis_start.y - y_axis_end.y
  rl.DrawLineEx(y_axis_start, y_axis_end, 5, ANALYTICS_COLOR)

  first_entry := state.session[0]
  last_entry := state.session[len(state.session)-1]
  total_minutes := time.duration_minutes(time.diff(first_entry.t, last_entry.t))

  x_axis_width := get_axis_end_x() - get_axis_start_x()


  total_by_minute: [dynamic]i32

  // Measure
  for current_minute in 0..=total_minutes {
    append(&total_by_minute, 0)
    for entry in state.session {
      diff_minutes := time.duration_minutes(time.diff(first_entry.t, entry.t))

      if diff_minutes <= current_minute {
        total_by_minute[cast(i32)current_minute] += entry.reps
      }
    }
  }

  max_total := cast(f32)total_by_minute[len(total_by_minute)-1]
  percentage_in_pixels := y_axis_height / 100

  // Draw
  for current_minute in 0..=total_minutes {
    current_total := cast(f32)total_by_minute[cast(i32)current_minute]
    y_percentage := 100 * (current_total / max_total)

    // ticks
    current_x := SCREEN_PADDING + (x_axis_width / cast(f32)total_minutes) * cast(f32)current_minute
    start_y := get_axis_y()
    end_y := start_y - 20

    rl.DrawLineEx(
      rl.Vector2 { current_x, start_y},
      rl.Vector2 { current_x, end_y},
      2,
      ANALYTICS_COLOR)

    minute_text := fmt.ctprintf("%v", current_minute)
    minute_text_position := rl.Vector2 {current_x, start_y + 20}
    text_size: f32 = 20
    rl.DrawTextEx(rl.GetFontDefault(), minute_text, minute_text_position, text_size, 1, ANALYTICS_COLOR)


    circle_y : f32 = start_y - cast(f32)y_percentage * percentage_in_pixels
    rl.DrawCircleV(rl.Vector2 {current_x, circle_y }, 5, ANALYTICS_COLOR)

  }
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
  height := entry.reps * COLUMN_MULTIPLIER
  offset := cast(f32)(idx) * (COLUMN_PADDING + width)

  color := TEXT_COLOR

  if idx % 2 == 0 {
    color = TEXT_COLOR_FADED
  }

  rl.DrawRectangleRec(
    rl.Rectangle {
      x = (get_axis_start_x() + offset),
      y = get_axis_y() - cast(f32) height,
      width = width,
      height = cast(f32) height,
    },
    color)

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

  rl.DrawTextEx(rl.GetFontDefault(), text, position, 54, 1, TEXT_COLOR)
}

render_session :: proc(state: ^State) {
  column_width := get_column_width(state.minutes, cast(i32)len(state.session))

  for &entry, idx in state.session {
    render_entry(idx, &entry, column_width)
  }

  render_total(state)
}

render_controls :: proc(state: ^State) {
  modal_width:f32 = 150
  modal_height:f32 = 60
  modal := rl.Rectangle {
    x = cast(f32)(rl.GetScreenWidth()/2) - (modal_width/2),
    y = cast(f32)(rl.GetScreenHeight()/2) - (modal_height/2),
    width = modal_width,
    height = modal_height,
  }

  if state.inputting {
    rl.DrawRectangleRec(modal, BG_COLOR)

    rl.DrawRectangleLinesEx(modal, 4, TEXT_COLOR)

    text_position := rl.Vector2 {
      modal.x + 10,
      modal.y + 7,
    }

    text: cstring = fmt.ctprintf("%v", convert_to_number(state.keys_pressed))

    rl.DrawTextEx(rl.GetFontDefault(), text, text_position, 50, 4, TEXT_COLOR)

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
  case .A:
    state.analytics = !state.analytics
  case .ZERO..=.NINE:
    state.inputting = true
    append(&state.keys_pressed, cast(u8)key)
  case .BACKSPACE:
    if len(state.keys_pressed) > 0 {
      pop(&state.keys_pressed)
    }
  case .ENTER:
    state.inputting = false
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
    analytics = true,
  }


  the_beginning := time.now()
  append(&state.session, Entry{reps = 6, t = the_beginning})
  append(&state.session, Entry{ reps = 8, t = time.time_add(the_beginning, 2 * time.Minute)})
  append(&state.session, Entry{ reps = 6, t = time.time_add(the_beginning, 4 * time.Minute)})
  append(&state.session, Entry{ reps = 8, t = time.time_add(the_beginning, 7 * time.Minute)})
  append(&state.session, Entry{ reps = 6, t = time.time_add(the_beginning, 10 * time.Minute)})
  append(&state.session, Entry{ reps = 8, t = time.time_add(the_beginning, 12 * time.Minute)})
  append(&state.session, Entry{ reps = 6, t = time.time_add(the_beginning, 15 * time.Minute)})
  append(&state.session, Entry{ reps = 8, t = time.time_add(the_beginning, 18 * time.Minute)})
  append(&state.session, Entry{ reps = 6, t = time.time_add(the_beginning, 20 * time.Minute)})


  parse_args(&state)

  rl.SetConfigFlags({
    .WINDOW_HIGHDPI,
    // .WINDOW_MAXIMIZED,
    // .WINDOW_RESIZABLE,
  })

  rl.InitWindow(1200, 800, "Couch")

  defer rl.CloseWindow()

  rl.SetTargetFPS(30)
  rl.EnableEventWaiting()

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()

    rl.ClearBackground(BG_COLOR)

    process_input(&state)

    if state.analytics {
      render_analytics(&state)
    } else {
      render_axis()
      render_session(&state)
      render_controls(&state)
    }

    rl.EndDrawing()
  }
}
