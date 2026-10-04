package main

import "core:fmt"
import "core:strings"
import "core:log"
import rl "vendor:raylib"

MENU_COLOR: rl.Color: { 170, 170, 170, 255}
MAIN_MENU_HEIGHT :: 32
ROW_HEIGHT :: 24
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

shadow :: proc(r: Rect) -> Rect {
  return Rect {
    x = r.x + 20,
    y = r.y + 20,
    width = r.width,
    height = r.height,
  }
}

draw_shadow :: proc(r: Rect) {
  rl.DrawRectangleRec(shadow(r), CGA_PALETTE[0])
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
  h := rl.MeasureTextEx(state.font, c_text, size, spacing).y
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

menu_item :: proc(container: Rect, state: ^State, label: string) -> (bool, Rect) {
  mouse := rl.GetMousePosition()
  item_id := WidgetID { name = label }
  slot, bar := cut_text_left(container, state, label, FontScale.Normal, TEXT_PAD_X*2)

  if rl.CheckCollisionPointRec(mouse, slot) {
    state.hot = item_id
  }

  item_hovered := state.hot.name == label
  item_clicked := item_hovered && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)

  if item_hovered {
    fill_solid(slot, CGA_PALETTE[2])
  }

  render_text_in_middle(slot, state, label, FontScale.Normal, CGA_PALETTE[0])

  return item_clicked, bar
}

render_sub_menu :: proc(menu_bar: Rect, state: ^State) {
  menu := state.main_menu[state.selected_main_menu_idx]
  if menu.items == nil do return

  mouse := rl.GetMousePosition()
  h_outter_padding: f32 = 20
  v_outter_padding: f32 = 15
  h_inner_padding: f32 = 25
  v_inner_padding: f32 = 25

  total_h_padding := (2 * h_outter_padding) + (2 * h_inner_padding)
  total_v_padding := (2 * v_outter_padding) + (2 * v_inner_padding)

  scale := FontScale.Normal

  // Menu container
  body := Rect {
    x = menu_bar.x,
    y = menu_bar.y + menu_bar.height,
    width = menu.size_normal.x + total_h_padding,
    height = menu.size_normal.y +total_v_padding
  }
  rl.DrawRectangleRec(shadow(body), CGA_PALETTE[0])
  rl.DrawRectangleRec(body, CGA_PALETTE[7])

  // Inner black border
  inner_body := inset(body, h_outter_padding, v_outter_padding)
  rl.DrawRectangleLinesEx(inner_body, 3, CGA_PALETTE[0])

  // Menu items
  inner_body = inset(inner_body, h_inner_padding, v_inner_padding)

  row: Rect
  for item, idx in menu.items {
    row, inner_body = cut_text_top(inner_body, state, item.label, scale, TEXT_PAD_Y)

    if state.current_z_layer == 1 {
      row_id := WidgetID { "main_sub_menu", idx }
      if rl.CheckCollisionPointRec(mouse, row) {
        state.hot = row_id
      }

      mouse_clicked := rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
      row_hovered := state.hot.name == row_id.name && state.hot.index == idx
      row_clicked := row_hovered && mouse_clicked

      if row_hovered {
        fill_solid(row, CGA_PALETTE[2])
      }

      if row_clicked {
        state.selected_main_menu_idx = -1
        state.current_z_layer = 0

        if item.screen != .None {
          state.current_screen = item.screen
        }
      } else if mouse_clicked {
        // Hide the main menu dropdown
        state.selected_main_menu_idx = -1
        state.current_z_layer = 0
      }
    }

    render_text(row, state, item.label, scale, CGA_PALETTE[0])
  }
}

render_main_menu :: proc(container: Rect, state: ^State) {
  fill_solid(container, CGA_PALETTE[7])
  text_color := CGA_PALETTE[0]
  bar := container
  menu_clicked := false

  for menu, idx in state.main_menu {
    if state.selected_main_menu_idx == idx {
      render_sub_menu(bar, state)
    }

    menu_clicked, bar = menu_item(bar, state, menu.label)
    if menu_clicked {
      state.selected_main_menu_idx = idx
      state.current_z_layer = 1
      if menu.screen != .None {
        state.current_screen = menu.screen
        state.current_z_layer = 0
      }
    }
  }
}

render_palette :: proc(container: Rect, state: ^State) {
  row, body_rest, text_slot: Rect
  body_container := inset(container, CONTAINER_PADDING, CONTAINER_PADDING)
  body_rest = body_container

  for i in 0..<len(CGA_PALETTE) {
    row, body_rest = cut_top(body_rest, ROW_HEIGHT + TEXT_PAD_X)

    color_slot, row_rest := cut_ratio_left(row, 0.3)
    color_slot = inset(color_slot, 3, 3)
    rl.DrawRectangleRec(color_slot, CGA_PALETTE[i])
    rl.DrawRectangleLinesEx(color_slot, 2, CGA_PALETTE[0])

    indx_str := fmt.tprintf("%v", i)
    text_slot, row_rest = cut_text_left(row_rest, state, indx_str, FontScale.Normal, TEXT_PAD_X)
    render_text(text_slot, state, indx_str, FontScale.Normal, CGA_PALETTE[14])

    body_rest.x = body_container.x
  }
}

render_cell_border_left :: proc(container: Rect) -> Rect {
  slot, container_rest := cut_left(container, 5)
  slot = center(slot, 3, slot.height)

  rl.DrawLineEx(
    {slot.x+slot.width, slot.y},
    {slot.x+slot.width, slot.y+slot.height}, 3, CGA_PALETTE[14])

  return container_rest
}

render_cell_border_right :: proc(container: Rect) -> Rect {
  slot, container_rest := cut_right(container, 5)
  slot = center(slot, 3, slot.height)

  rl.DrawLineEx(
    {slot.x+slot.width, slot.y},
    {slot.x+slot.width, slot.y+slot.height}, 3, CGA_PALETTE[14])

  return container_rest

}

render_workout_row :: proc(row: Rect, idx: int, state: ^State) -> bool {
  mouse := rl.GetMousePosition()
  item_id := WidgetID { name = "workout_row", index = idx }
  slot, row_rest: Rect
  font_scale := FontScale.Normal
  workout := state.workouts[idx]

  if rl.CheckCollisionPointRec(mouse, row) {
    state.hot = item_id
  }

  row_hovered := state.hot.name == item_id.name && state.hot.index == item_id.index
  row_clicked := row_hovered && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)

  if row_hovered {
    fill_solid(row, CGA_PALETTE[2])
  }

  // First Cell: ID
  row_rest = render_cell_border_left(row)
  id_str := fmt.tprintf("%v", workout.id)
  slot, row_rest = cut_text_left(row_rest, state, "ID", font_scale, TEXT_PAD_X)
  render_text_in_middle(slot, state, id_str, font_scale, CGA_PALETTE[15])

  // Second Cell: title
  row_rest = render_cell_border_left(row_rest)
  slot, row_rest = cut_ratio_left(row_rest, 0.8)
  render_padded_text(slot, state, workout.name, font_scale, CGA_PALETTE[15], TEXT_PAD_X)

  // Third Cell: duration
  row_rest = render_cell_border_left(row_rest)
  duration_str := fmt.tprintf("%v", workout.duration)
  render_text_in_middle(row_rest, state, duration_str, font_scale, CGA_PALETTE[15])

  render_cell_border_right(row_rest)

  return row_clicked
}

render_modal_reps_input :: proc(container: Rect, state: ^State) {
  modal_width:f32 = 150
  modal_height:f32 = 60
  modal := rl.Rectangle {
    x = cast(f32)(container.width/2) - (modal_width/2),
    y = cast(f32)(container.height/2) - (modal_height/2),
    width = modal_width,
    height = modal_height,
  }

  rl.DrawRectangleRec(shadow(modal), CGA_PALETTE[0])
  rl.DrawRectangleRec(modal, CGA_PALETTE[1])

  rl.DrawRectangleLinesEx(modal, 4, CGA_PALETTE[14])

  text := fmt.tprintf("%v", convert_to_number(state.keys_pressed))
  font_size: f32 = 50

  render_text_in_middle(modal, state, text, FontScale.Big, CGA_PALETTE[14])
}

//  ═ (0x2550): Double Horizontal
//  ║ (0x2551): Double Vertical
//  ╔ (0x2554): Double Down and Right
//  ╗ (0x2557): Double Down and Left
//  ╚ (0x255A): Double Up and Right
//  ╝ (0x255D): Double Up and Left

render_modal_ex_list :: proc(container: Rect, state: ^State) {
  slot := inset(container, 300, 200)
  size, spacing := font_metrics(state, FontScale.Normal)
  cell_w := rl.MeasureTextEx(state.font, "A", size, spacing).x

  workout := state.workouts[state.selected_workout_index]
  // draw_shadow(slot)
  fill_solid(slot, CGA_PALETTE[7])


  slot = inset(slot, 5, 5)
  rl.DrawRectangleLinesEx(slot, 2, CGA_PALETTE[15])
  slot = inset(slot, 5, 5)
  rl.DrawRectangleLinesEx(slot, 2, CGA_PALETTE[15])

  // Horizontal borders
  // for x_step: f32 = cell_w; x_step + cell_w < slot.width; x_step += cell_w {
  //   rl.DrawTextCodepoint(state.font, 0x2550, {slot.x + x_step, slot.y}, size, CGA_PALETTE[15])
  //   rl.DrawTextCodepoint(state.font, 0x2550, {slot.x + x_step, slot.y + slot.height - size}, size, CGA_PALETTE[15])
  // }

  // state.selected_workout_index = -1
}

render_workouts_list :: proc(container: Rect, state: ^State) {
  font_scale := FontScale.Normal
  row_height := f32(state.font.baseSize) * f32(font_scale)
  get_all_workouts(state)

  slot, row, body_rest, text_slot, row_rest: Rect
  body_container := inset(container, CONTAINER_PADDING, CONTAINER_PADDING)
  body_rest = body_container

  // Header
  row, body_rest = cut_top(body_rest, row_height)
  row_rest = render_cell_border_left(row)
  header := "ID"
  slot, row_rest = cut_text_left(row_rest, state, header, font_scale, TEXT_PAD_X)
  render_text_in_middle(slot, state, header, font_scale, CGA_PALETTE[14])
  row_rest = render_cell_border_left(row_rest)

  header = "Title"
  slot, row_rest = cut_ratio_left(row_rest, 0.8)
  render_text_in_middle(slot, state, header, font_scale, CGA_PALETTE[14])
  row_rest = render_cell_border_left(row_rest)

  header = "Duration"
  render_text_in_middle(row_rest, state, header, font_scale, CGA_PALETTE[14])
  render_cell_border_right(row_rest)

  _, body_rest = cut_top(body_rest, 3 * TEXT_PAD_Y)

  for idx in 0..<len(state.workouts) {
    row, body_rest = cut_top(body_rest, row_height)
    if render_workout_row(row, idx, state) {
      state.current_modal = .WorkoutDetails
      state.selected_workout_index = idx
    }
  }
}


render_exercises_list :: proc(container: Rect, state: ^State) {
  font_scale := FontScale.Normal
  row_height := f32(state.font.baseSize) * f32(font_scale)
  get_all_exercise(state)

  slot, row, body_rest, text_slot, row_rest: Rect
  body_container := inset(container, CONTAINER_PADDING, CONTAINER_PADDING)
  body_rest = body_container

  // Header
  row, body_rest = cut_top(body_rest, row_height)
  row_rest = render_cell_border_left(row)
  header := "ID"
  slot, row_rest = cut_text_left(row_rest, state, header, font_scale, TEXT_PAD_X)
  render_text_in_middle(slot, state, header, font_scale, CGA_PALETTE[14])
  row_rest = render_cell_border_left(row_rest)

  header = "Title"
  render_text_in_middle(row_rest, state, header, font_scale, CGA_PALETTE[14])
  render_cell_border_right(row_rest)

  _, body_rest = cut_top(body_rest, 3 * TEXT_PAD_Y)

  for idx in 0..<len(state.exercises) {
    exercise := state.exercises[idx]
    row, body_rest = cut_top(body_rest, row_height)

    // First Cell: ID
    row_rest = render_cell_border_left(row)
    id_str := fmt.tprintf("%v", exercise.id)
    slot, row_rest = cut_text_left(row_rest, state, "ID", font_scale, TEXT_PAD_X)
    render_text_in_middle(slot, state, id_str, font_scale, CGA_PALETTE[15])

    // Second Cell: title
    row_rest = render_cell_border_left(row_rest)
    text_slot, row_rest = cut_text_left(row_rest, state, exercise.name, font_scale, TEXT_PAD_X)
    render_padded_text(text_slot, state, exercise.name, font_scale, CGA_PALETTE[15], TEXT_PAD_X)

    render_cell_border_right(row_rest)
  }
}

render_status_bar :: proc(container: Rect, state: ^State) {
  fill_solid(container, CGA_PALETTE[7])
  slot, bar : Rect

  help_command_text : string
  help_hint_text : string

  #partial switch state.current_screen {
    case .Start: {
      help_command_text = "SPACE"
      help_hint_text = "Start your session"
    }
    case .Tracking: {
      help_command_text = "0-9"
      help_hint_text = "Get input box to enter your reps"
    }
    case: return
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
    strings.write_string(&b, ex.name)
  }

  return strings.to_string(b)
}

render_sessions_list :: proc(container: Rect, state: ^State) {
  row : Rect
  body_rest := container
  vline := "|"
  mouse := rl.GetMousePosition()

  for idx in 0..<len(state.sessions) {
    row_text_color := CGA_PALETTE[14]
    row_id := WidgetID { "session_row", idx }

    session := state.sessions[idx]
    row, body_rest = cut_top(body_rest, ROW_HEIGHT + TEXT_PAD_X)

    if state.current_z_layer == 0 {
      if rl.CheckCollisionPointRec(mouse, row) {
        state.hot = row_id
      }

      row_hovered := state.hot.name == row_id.name && state.hot.index == idx
      row_clicked := row_hovered && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
      if row_hovered {
        fill_solid(row, CGA_PALETTE[14])
        row_text_color = CGA_PALETTE[1]
      }

      if row_clicked {
        state.selected_session_index = idx
      }
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


