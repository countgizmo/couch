package main

import rl "vendor:raylib"

MENU_COLOR: rl.Color: { 170, 170, 170, 255}
MAIN_MENU_HEIGHT :: 30

render_main_menu :: proc(container: rl.Rectangle, state: ^State) {
  menu := rl.Rectangle {
    x = container.x,
    y = container.y,
    width = container.width,
    height = MAIN_MENU_HEIGHT,
  }

  rl.DrawRectangleRec(menu, MENU_COLOR)
}
