package main

FONT_DATA    :: #load("../assets/Px437_IBM_VGA_8x16.ttf")
TEXT_PAD_X   :: 8

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
