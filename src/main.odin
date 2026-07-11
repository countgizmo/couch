package main

import "core:fmt"
import "core:time"
import "core:log"
import "core:strconv"
import "core:os"
import "core:math"
import rl "vendor:raylib"

Animation :: struct {
  elapsed: f32,
  duration: f32,
  from: f32,
  to: f32,
  running: bool,
}

animate_pulsing :: proc(animation: Animation) -> f32 {
  t := (math.sin(animation.elapsed * 2) + 1) / 2
  next_value := animation.from + (animation.to - animation.from) * t
  return next_value
}

animate_linear :: proc(animation: Animation) -> f32 {
  t_raw := animation.elapsed / animation.duration
  t_normal := math.clamp(t_raw, 0.0, 1.0)
  t_eased := 1 - (1 - t_normal) * (1 - t_normal)
  next_value := animation.from + (animation.to - animation.from) * t_eased
  return next_value
}

State :: struct {
  start: time.Time,
  seconds_from_start: f32,
  session: [dynamic]Entry,
  started: bool,
  paused: bool,
  done: bool,


  // Setup
  exercises: i32,
  minutes: i32,


  // Controls
  keys_pressed: [dynamic]u8,
  inputting: bool,
  analytics: bool,

  // Animation
  hr_beat_animation: Animation,

  // View
  bars: [dynamic]BarView
}

Entry :: struct {
  reps: i32,
  t: time.Time,
}

BarView :: struct {
  entry_index: int,
  animation: Animation,
}

SCREEN_WIDTH :: 1200
SCREEN_HEIGHT :: 800
CONTAINER_PADDING :: 40
COLUMN_PADDING: f32 = 10

TEXT_COLOR :rl.Color: {128, 128, 0, 255}
BG_COLOR :rl.Color: {0, 0, 128, 255}
SHADOW_COLOR :rl.Color: {0, 0, 0, 150}
TEXT_COLOR_FADED :rl.Color: {128, 128, 0, 150}
ANALYTICS_COLOR :rl.Color: {128, 128, 128, 255}

minutes_to_seconds :: proc(minutes: i32) -> f32 {
  return cast(f32) minutes * 60
}

render_text_in_middle :: proc (container: rl.Rectangle, text: string, font_size: f32, color: rl.Color) {
    c_text := fmt.ctprint(text)
    text_size:= rl.MeasureTextEx(rl.GetFontDefault(), c_text, font_size, 1)

    container_middle_width := container.width / 2
    container_middle_height := container.height / 2

    text_position := rl.Vector2 {
      container.x + container_middle_width - text_size.x/2,
      container.y + container_middle_height - text_size.y/2}

    rl.DrawTextEx(rl.GetFontDefault(), c_text, text_position, font_size, 2, color)
}

get_column_width :: proc(container: rl.Rectangle, chunks: i32, count: i32) -> f32 {
  chunks_based := container.width / cast(f32)chunks

  total_width_needed := (chunks_based + COLUMN_PADDING) * cast(f32)count + 50

  if total_width_needed > container.width {

    total_padding := COLUMN_PADDING * cast(f32)count
    available_width := container.width - total_padding

    //NOTE(evgheni): add an extra space for one more to get end padding
    dynamic_width := available_width / cast(f32)(count+1)
    return dynamic_width
  }

  return chunks_based
}

// render_analytics :: proc(state: ^State) {
//
//   // Nothing to report
//   if len(state.session) == 0 {
//     return
//   }
//
//
//   first_entry := state.session[0]
//   last_entry := state.session[len(state.session)-1]
//   total_minutes := time.duration_minutes(time.diff(first_entry.t, last_entry.t))
//
//   x_axis_width := get_axis_end_x() - get_axis_start_x()
//
//
//   total_by_minute: [dynamic]i32
//
//   // Measure
//   for current_minute in 0..=total_minutes {
//     append(&total_by_minute, 0)
//     for entry in state.session {
//       diff_minutes := time.duration_minutes(time.diff(first_entry.t, entry.t))
//
//       if diff_minutes <= current_minute {
//         total_by_minute[cast(i32)current_minute] += entry.reps
//       }
//     }
//   }
//
//   max_total := cast(f32)total_by_minute[len(total_by_minute)-1]
//   percentage_in_pixels := state.y_axis.height / 100
//
//   // Draw
//   for current_minute in 0..=total_minutes {
//     current_total := cast(f32)total_by_minute[cast(i32)current_minute]
//     y_percentage := 100 * (current_total / max_total)
//
//     // ticks
//     current_x := CONTAINER_PADDING + (x_axis_width / cast(f32)total_minutes) * cast(f32)current_minute
//     start_y := get_axis_y()
//     end_y := start_y - 20
//
//     rl.DrawLineEx(
//       rl.Vector2 { current_x, start_y },
//       rl.Vector2 { current_x, end_y },
//       2,
//       ANALYTICS_COLOR)
//
//     minute_text := fmt.ctprintf("%v", current_minute)
//     minute_text_position := rl.Vector2 {current_x, start_y + 20}
//     text_size: f32 = 20
//     rl.DrawTextEx(rl.GetFontDefault(), minute_text, minute_text_position, text_size, 1, ANALYTICS_COLOR)
//
//
//     circle_y : f32 = start_y - cast(f32)y_percentage * percentage_in_pixels
//     rl.DrawCircleV(rl.Vector2 {current_x, circle_y }, 5, ANALYTICS_COLOR)
//
//   }
// }

render_axis :: proc(container: rl.Rectangle, color: rl.Color) {
  axis_start := rl.Vector2 {
    container.x,
    container.y + container.height,
  }

  x_axis_end := rl.Vector2 {
    container.x + container.width,
    container.y + container.height,
  }

  y_axis_end := rl.Vector2 {
    container.x,
    container.y,
  }

  rl.DrawLineEx(axis_start, x_axis_end, 5, color)
  rl.DrawLineEx(axis_start, y_axis_end, 5, color)
}

render_entry :: proc(container: rl.Rectangle, state: ^State, idx: int, width: f32, max_reps: i32) {
  bar_view := state.bars[idx]
  entry := state.session[bar_view.entry_index]
  offset := cast(f32)(idx) * (COLUMN_PADDING + width)

  color := TEXT_COLOR

  if idx % 2 == 0 {
    color = TEXT_COLOR_FADED
  }

  max_percentage := animate_linear(bar_view.animation)

  percentage_in_pixels := (container.height - CONTAINER_PADDING) / 100
  column_height_percentage := max_percentage * (cast(f32)entry.reps / cast(f32)max_reps)
  column_height := column_height_percentage * percentage_in_pixels

  column := rl.Rectangle {
    x = container.x + offset,
    y = container.y + container.height - column_height,
    width = width,
    height = column_height,
  }

  rl.DrawRectangleRec(column, color)

  if !bar_view.animation.running {
    reps_text := fmt.ctprintf("%v", entry.reps)
    font_size: f32 = 40
    text_position := rl.Vector2 {
      COLUMN_PADDING + column.x,
      column.y - font_size,
    }

    rl.DrawTextEx(rl.GetFontDefault(), reps_text, text_position, font_size, 1, color)
  }
}

render_total :: proc(container: rl.Rectangle, state: ^State) {
  text: string

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

    text = fmt.tprintf("TOTAL: %v | %v", total1, total2)
  } else if state.exercises == 1 {
    total: i32
    for e in state.session {
      total += e.reps
    }

    text = fmt.tprintf("TOTAL: %v", total)
  } else {
    text = "WTF"
  }

  total_container := rl.Rectangle {
    x = container.x,
    y = container.y,
    width = container.width/2,
    height = container.height,
  }

  font_size: f32 = 50
  render_text_in_middle(total_container, text, font_size, TEXT_COLOR)
}

render_heart_rate :: proc(container: rl.Rectangle, state: ^State) {
  hr_container := rl.Rectangle {
    x = container.x + (container.width/2),
    y = container.y,
    width = container.width/2,
    height = container.height,
  }

  font_size := animate_pulsing(state.hr_beat_animation)
  hr_text := fmt.tprintf("%d", heart_rate)
  render_text_in_middle(hr_container, hr_text, font_size, TEXT_COLOR)
}

render_session :: proc(container: rl.Rectangle, state: ^State) {
  column_width := get_column_width(container, state.minutes, cast(i32)len(state.session))
  max_reps: i32 = 0

  for &entry, idx in state.session {
    if entry.reps > max_reps {
      max_reps = entry.reps
    }
  }

  for idx in 0..<len(state.bars) {
    render_entry(container, state, idx, column_width, max_reps)
  }
}

render_controls :: proc(container: rl.Rectangle, state: ^State) {
  if state.inputting {
    modal_width:f32 = 150
    modal_height:f32 = 60
    modal := rl.Rectangle {
      x = cast(f32)(container.width/2) - (modal_width/2),
      y = cast(f32)(container.height/2) - (modal_height/2),
      width = modal_width,
      height = modal_height,
    }

    shadow := rl.Rectangle {
      x = modal.x + 20,
      y = modal.y + 20,
      width = modal_width,
      height = modal_height,
    }

    rl.DrawRectangleRec(shadow, SHADOW_COLOR)
    rl.DrawRectangleRec(modal, BG_COLOR)


    rl.DrawRectangleLinesEx(modal, 4, TEXT_COLOR)

    text := fmt.tprintf("%v", convert_to_number(state.keys_pressed))
    font_size: f32 = 50

    render_text_in_middle(modal, text, font_size, TEXT_COLOR)
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

update :: proc(state: ^State) {

  // Time
  if !state.paused && state.started {
    state.seconds_from_start += rl.GetFrameTime()
  }

  // Are we done yet?
  total_seconds := minutes_to_seconds(state.minutes)
  if state.seconds_from_start >= total_seconds {
    state.done = true
    state.paused = true
  }


  // Keyboard

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
    append(&state.bars, BarView{
      entry_index = len(state.session) - 1,
      animation = Animation {
        duration = 0.4,
        from = 0,
        to = 100,
        running = true,
      },
    })
    clear(&state.keys_pressed)
  case .SPACE:
    if !state.started {
      state.start = time.now()
      state.started = true
    } else {
      state.paused = !state.paused
    }
  }

  // Animation
  if state.hr_beat_animation.running {
    state.hr_beat_animation.elapsed += rl.GetFrameTime()
  }

  for &bar_view in state.bars {
    if bar_view.animation.running {
      bar_view.animation.elapsed += rl.GetFrameTime()
      if bar_view.animation.elapsed >= bar_view.animation.duration {
        bar_view.animation.running = false
      }
    }
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

render_start_screen :: proc(container: rl.Rectangle) {
  container_middle_width := container.width / 2
  container_middle_height := container.height / 2

  welcome_text := "Press SPACE to start"
  font_size: f32 = 20
  render_text_in_middle(container, welcome_text, font_size, TEXT_COLOR)
}

render_progress_bar :: proc(container: rl.Rectangle, state: ^State) {
  total_seconds := minutes_to_seconds(state.minutes)
  percentage_in_pixels := container.width / total_seconds

  bar_width: f32

  if state.done {
    bar_width = container.width
  } else {
    bar_width = percentage_in_pixels * state.seconds_from_start
  }

  bar := rl.Rectangle {
    x = container.x,
    y = container.y,
    width = bar_width,
    height = container.height,
  }

  rl.DrawRectangleLinesEx(container, 5, TEXT_COLOR)
  rl.DrawRectangleRec(bar, TEXT_COLOR)

  if state.done {
    render_text_in_middle(bar, "Done", 40, BG_COLOR)
  }
}

render_live_session :: proc(state: ^State) {
  window_height := cast(f32) rl.GetScreenHeight()
  info_section_height     := window_height * 10 / 100
  tracking_section_height := window_height * 60 / 100
  progress_section_height := window_height - info_section_height - tracking_section_height - CONTAINER_PADDING

  info_section := rl.Rectangle {
    x = CONTAINER_PADDING,
    y = CONTAINER_PADDING,
    width =  cast(f32) rl.GetScreenWidth() - (2*CONTAINER_PADDING),
    height = info_section_height - CONTAINER_PADDING,
  }

  tracking_section := rl.Rectangle {
    x = CONTAINER_PADDING,
    y = CONTAINER_PADDING + info_section.y + info_section.height,
    width =  cast(f32) rl.GetScreenWidth() - (2*CONTAINER_PADDING),
    height = tracking_section_height - CONTAINER_PADDING,
  }

  progress_section := rl.Rectangle {
    x = CONTAINER_PADDING,
    y = CONTAINER_PADDING + tracking_section.y + tracking_section.height,
    width =  cast(f32) rl.GetScreenWidth() - (2*CONTAINER_PADDING),
    height = progress_section_height - CONTAINER_PADDING,
  }


  render_total(info_section, state)
  render_heart_rate(info_section, state)
  render_axis(tracking_section, TEXT_COLOR)
  render_session(tracking_section, state)
  render_controls(tracking_section, state)
  render_progress_bar(progress_section, state)
}

render :: proc(state: ^State) {
  if !state.started {
    screen := rl.Rectangle {
      x = 0,
      y = 0,
      width =  cast(f32) rl.GetScreenWidth(),
      height = cast(f32) rl.GetScreenHeight(),
    }

    render_start_screen(screen)

    return
  }


  // TODO: fix it!
  if state.analytics {
    //render_axis(tracking_section, ANALYTICS_COLOR)
    // render_analytics(state)
  } else {
    render_live_session(state)
  }
}

main :: proc() {
  context.logger = log.create_console_logger()

  cb_central_manager := init_whoop_reading()

  rl.SetConfigFlags({
    .WINDOW_HIGHDPI,
    .WINDOW_MAXIMIZED,
    .WINDOW_RESIZABLE,
  })

  rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Couch")

  defer rl.CloseWindow()

  rl.SetTargetFPS(30)
  rl.SetExitKey(.KEY_NULL);

  state := State {
    exercises = 1,
    minutes = 20,
    analytics = false,
    started = false,
    paused = false,
  }

  state.hr_beat_animation = Animation {
    duration = 10,
    from = 50,
    to = 70,
    running = true,
  }

  parse_args(&state)

  whoop_connected := false

  for !rl.WindowShouldClose() {
    if whoop != nil && !whoop_connected {
      fmt.println(">>> WHOOP DETECTED = ", whoop->name()->odinString())
      cb_central_manager->connectPeripheral(whoop, nil)
      whoop_connected = true
    }
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    update(&state)
    render(&state)
    rl.EndDrawing()
  }

  whoop->release()
}
