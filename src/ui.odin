package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

MENU_COLOR: rl.Color: { 170, 170, 170, 255}
MAIN_MENU_HEIGHT :: 30
ROW_HEIGHT :: 20
FONT_SIZE :: 16

CGA_PALETTE := [16]rl.Color{
    { 0,   0,   0,   255 }, // 0  black
    { 0,   0,   168, 255 }, // 1  blue
    { 0,   168, 0,   255 }, // 2  green
    { 0,   168, 168, 255 }, // 3  cyan
    { 168, 0,   0,   255 }, // 4  red
    { 168, 0,   168, 255 }, // 5  magenta
    { 168, 84,  0,   255 }, // 6  brown
    { 168, 168, 168, 255 }, // 7  light grey
    { 84,  84,  84,  255 }, // 8  dark grey
    { 84,  84,  252, 255 }, // 9  bright blue
    { 84,  252, 84,  255 }, // 10 bright green
    { 84,  252, 252, 255 }, // 11 bright cyan
    { 252, 84,  84,  255 }, // 12 bright red
    { 252, 84,  252, 255 }, // 13 bright magenta
    { 252, 252, 84,  255 }, // 14 yellow
    { 252, 252, 252, 255 }, // 15 white
}

Rect :: rl.Rectangle

WidgetID :: struct {
  name: string,
  // in case the widget is in a collection
  index: int,
}

cut_top :: proc(r: Rect, h: f32) -> (strip, rest: Rect) {
  strip = { r.x, r.y, r.width, h }
  rest = { r.x, r.y + h, r.width, r.height - h }
  return
}

cut_bottom :: proc(r: Rect, h: f32) -> (strip, rest:Rect) {
  rest, strip = cut_top(r, r.height - h)
  return
}

cut_left :: proc(r: Rect, w: f32) -> (strip, rest: Rect) {
  strip = { r.x, r.y, w, r.height }
  rest = { r.x + w, r.y, r.width - w, r.height }
  return
}

cut_right :: proc(r: Rect, w: f32) -> (strip, rest: Rect) {
  rest, strip = cut_left(r, r.width - w)
  return
}

cut_ratio_left :: proc(r: Rect, width_ratio: f32) -> (strip, rest: Rect) {
  w := r.width * width_ratio
  return cut_left(r, w)
}

cut_ratio_bottom :: proc(r: Rect, height_ratio: f32) -> (strip, rest: Rect) {
  h := r.height * height_ratio
  return cut_bottom(r, h)
}

cut_text_left :: proc(r: Rect, state: ^State, s: string, scale: FontScale, pad: f32) -> (slot, rect: Rect) {
  c_text := fmt.ctprint(s)
  size, spacing := font_metrics(state, scale)
  w := rl.MeasureTextEx(state.font, c_text, size, spacing).x
  return cut_left(r, w + (2 * pad))
}

cut_text_right :: proc(r: Rect, state: ^State, s: string, scale: FontScale, pad: f32) -> (slot, rect: Rect) {
  c_text := fmt.ctprint(s)
  size, spacing := font_metrics(state, scale)
  w := rl.MeasureTextEx(state.font, c_text, size, spacing).x
  return cut_right(r, w + (2 * pad))
}

cut_text_top :: proc(r: Rect, state: ^State, s: string, scale: FontScale, pad: f32) -> (slot, rect: Rect) {
  c_text := fmt.ctprint(s)
  size, spacing := font_metrics(state, scale)
  h := rl.MeasureTextEx(state.font, c_text, size, spacing).x
  return cut_top(r, h + (2 * pad))
}

inset :: proc(r: Rect, dx, dy: f32) -> Rect {
  return { r.x + dx, r.y + dy, r.width - (2*dx), r.height - (2*dy) }
}

center :: proc(r: Rect, w: f32, h: f32) -> Rect {
  return { r.x + (r.width - w)/2, r.y + (r.height - h)/2, w, h }
}

fill_solid :: proc(container: Rect, color: rl.Color) {
  rl.DrawRectangleRec(container, color)
}



render_main_menu :: proc(container: Rect, state: ^State) {
  fill_solid(container, CGA_PALETTE[7])
  render_text(container, state, "Couch", FontScale.Normal, CGA_PALETTE[0])
}

render_status_bar :: proc(container: Rect, state: ^State) {
  fill_solid(container, CGA_PALETTE[7])
  slot, bar : Rect

  help_command_text : string
  help_hint_text : string

  switch state.current_screen {
    case .Start: {
      help_command_text = "SPACE"
      help_hint_text = "Start your session"
    }
    case .Tracking: {
      help_command_text = "0-9"
      help_hint_text = "Get input box to enter your reps"
    }
  }

  slot, bar = cut_text_left(container, state, help_command_text, FontScale.Normal, TEXT_PAD_X)
  render_text_in_middle(slot, state, help_command_text, FontScale.Normal, CGA_PALETTE[4])

  slot, bar = cut_left(bar, 10)
  slot = center(slot, 3, slot.height)
  rl.DrawLineEx({slot.x+slot.width, slot.y}, {slot.x+slot.width, slot.y+slot.height}, 3, CGA_PALETTE[0])

  slot, bar = cut_text_left(bar, state, help_hint_text, FontScale.Normal, TEXT_PAD_X)
  render_text_in_middle(slot, state, help_hint_text, FontScale.Normal, CGA_PALETTE[0])
}

make_session_name :: proc(session: Session, allocator := context.temp_allocator) -> string {
  b := strings.builder_make(allocator)
  for ex, i in session.exercises {
    if i > 0 do strings.write_string(&b, " + ")
    strings.write_string(&b, ex.title)
  }

  return strings.to_string(b)
}

render_sessions_list :: proc(container: Rect, state: ^State) {
  row : Rect
  body_rest := container
  vline := "|"
  mouse := rl.GetMousePosition()
  row_text_color : rl.Color

  for idx in 0..<len(state.sessions) {
    row_id := WidgetID { "session_row", idx }

    session := state.sessions[idx]
    row, body_rest = cut_top(body_rest, ROW_HEIGHT + TEXT_PAD_X)

    // Check for hover
    if rl.CheckCollisionPointRec(mouse, row) {
      state.hot = row_id
    }

    // Checking for all the interactions
    row_hovered := state.hot.name == row_id.name && state.hot.index == idx
    row_clicked := row_hovered && rl.IsMouseButtonDown(rl.MouseButton.LEFT)

    if row_hovered {
      fill_solid(row, CGA_PALETTE[14])
      row_text_color = CGA_PALETTE[1]
    } else {
      row_text_color = CGA_PALETTE[14]
    }

    if row_clicked {
      state.selected_session_index = idx
    }

    if idx == state.selected_session_index {
      fill_solid(row, CGA_PALETTE[2])
    }

    // First Cell
    slot, row_rest := cut_ratio_left(row, 0.7)

    text_slot, slot_rest := cut_text_left(slot, state, vline, FontScale.Normal, TEXT_PAD_X)
    render_text(text_slot, state, vline, FontScale.Normal, row_text_color)

    session_name := make_session_name(session)
    text_slot, slot_rest = cut_text_left(slot_rest, state, session_name, FontScale.Normal, TEXT_PAD_X)
    render_text(text_slot, state, session_name, FontScale.Normal, row_text_color)

    text_slot, slot_rest = cut_text_right(slot_rest, state, vline, FontScale.Normal, TEXT_PAD_X)
    render_text(text_slot, state, vline, FontScale.Normal, row_text_color)

    // Second Cell
    duration_text := fmt.tprintf("%v (min)", session.duration_minutes)
    text_slot, slot_rest = cut_text_left(row_rest, state, duration_text, FontScale.Normal, TEXT_PAD_X)
    render_text(text_slot, state, duration_text, FontScale.Normal, row_text_color)

    text_slot, slot_rest = cut_text_right(slot_rest, state, vline, FontScale.Normal, TEXT_PAD_X)
    render_text(text_slot, state, vline, FontScale.Normal, row_text_color)

    // Next row starts from the left
    body_rest.x = container.x
  }
}


