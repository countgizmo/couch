package main

import "core:fmt"
import rl "vendor:raylib"

FONT_DATA    :: #load("../assets/Px437_IBM_VGA_8x16.ttf")
TEXT_PAD_X   :: 8
TEXT_PAD_Y   :: 2

FontScale :: enum i32 {
  Small  = 1,
  Normal = 2,
  Big    = 3,
}

font_metrics :: proc(state: ^State, scale: FontScale) -> (size, spacing: f32) {
    size = f32(state.font.baseSize) * f32(int(scale))
    spacing = 0
    return
}

render_text_in_middle :: proc (container: rl.Rectangle, state: ^State, text: string, scale: FontScale, color: rl.Color) {
  size, spacing := font_metrics(state, scale)
  c_text := fmt.ctprint(text)
  text_size:= rl.MeasureTextEx(state.font, c_text, size, spacing)
  container_center := center(container, text_size.x, text_size.y)
  text_position := rl.Vector2 { container_center.x, container_center.y}
  rl.DrawTextEx(state.font, c_text, text_position, size, spacing, color)
}

render_text :: proc(container: Rect, state: ^State, text: string, scale: FontScale, color: rl.Color) {
  size, spacing := font_metrics(state, scale)
  c_text := fmt.ctprint(text)
  text_position := rl.Vector2 { container.x + TEXT_PAD_X, container.y}
  rl.DrawTextEx(state.font, c_text, text_position, size, spacing, color)
}
