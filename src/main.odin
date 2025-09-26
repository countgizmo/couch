package main

import "core:fmt"
import "core:time"

Entry :: struct {
  reps: i8,
  time: time.Tick,
}

main :: proc() {
  session: [30]Entry
  start := time.tick_now()

  time.sleep(time.Second * 3)

  entry := Entry {
    reps = 3,
    time = time.tick_now(),
  }

  duration_since_start := time.tick_diff(start, entry.time)
  fmt.printf("Entry 1. Reps = %d. Since start = %v ",
    entry.reps, time.duration_seconds(duration_since_start))
}
