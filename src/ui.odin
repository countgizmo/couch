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

cut_top :: proc(r: Rect, h: f32) -> (strip: Rect, rest: Rect) {
  strip = { r.x, r.y, r.width, h }
  rest = { r.x, r.y + h, r.width, r.height - h }
  return
}

render_main_menu :: proc(container: Rect, state: ^State) {
  rl.DrawRectangleRec(container, CGA_PALETTE[7])
}
