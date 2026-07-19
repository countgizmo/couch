package main

import rl "vendor:raylib"

MENU_COLOR: rl.Color: { 170, 170, 170, 255}
MAIN_MENU_HEIGHT :: 30

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

inset :: proc(r: Rect, dx, dy: f32) -> Rect {
  return { r.x + dx, r.y + dy, r.width - (2*dx), r.height - (2*dy) }
}

render_main_menu :: proc(container: Rect, state: ^State) {
  rl.DrawRectangleRec(container, CGA_PALETTE[7])
}

render_status_bar :: proc(container: Rect, state: ^State) {
  rl.DrawRectangleRec(container, CGA_PALETTE[7])

  help_command_area, rest := cut_left(container, 100)
  help_command_text_area := inset(help_command_area, 10, 6)
  help_hint_area, _ := cut_left(rest, 300)
  help_hint_text_area := inset(help_hint_area, 10, 6)



  render_text_in_middle(help_command_text_area, "0-9", help_command_text_area.height, CGA_PALETTE[0])
  render_text_in_middle(help_hint_text_area, "Get input box to enter your reps", help_hint_text_area.height, CGA_PALETTE[0])



}

