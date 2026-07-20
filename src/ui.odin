package main

import "core:fmt"
import rl "vendor:raylib"

MENU_COLOR: rl.Color: { 170, 170, 170, 255}
MAIN_MENU_HEIGHT :: 30
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

cut_text :: proc(r: Rect, state: ^State, s: string, scale: FontScale, pad: f32) -> (slot, rect: Rect) {
  c_text := fmt.ctprint(s)
  size, spacing := font_metrics(state, scale)
  w := rl.MeasureTextEx(state.font, c_text, size, spacing).x
  return cut_left(r, w + (2 * pad))
}

inset :: proc(r: Rect, dx, dy: f32) -> Rect {
  return { r.x + dx, r.y + dy, r.width - (2*dx), r.height - (2*dy) }
}

center :: proc(r: Rect, w: f32, h: f32) -> Rect {
  return { r.x + (r.width - w)/2, r.y + (r.height - h)/2, w, h }
}

render_main_menu :: proc(container: Rect, state: ^State) {
  rl.DrawRectangleRec(container, CGA_PALETTE[7])
}

render_status_bar :: proc(container: Rect, state: ^State) {
  rl.DrawRectangleRec(container, CGA_PALETTE[7])
  slot, bar : Rect

  help_command_text := "0-9"
  slot, bar = cut_text(container, state, help_command_text, FontScale.Normal, TEXT_PAD_X)
  render_text_in_middle(slot, state, help_command_text, FontScale.Normal, CGA_PALETTE[0])

  help_hint_text := "Get input box to enter your reps"
  slot, bar = cut_text(bar, state, help_hint_text, FontScale.Normal, TEXT_PAD_X)
  render_text_in_middle(slot, state, help_hint_text, FontScale.Normal, CGA_PALETTE[0])


  // help_command_text_area := inset(help_command_area, 10, 6)
  // help_hint_area, _ := cut_left(rest, 300)
  // help_hint_text_area := inset(help_hint_area, 10, 6)
  //
  // render_text_in_middle(help_hint_text_area, state, "Get input box to enter your reps", FontScale.Normal, CGA_PALETTE[0])
}

