package main

import "core:fmt"
import "core:mem"
import "core:os"
import rl "vendor:raylib"

CELL_WIDTH :: 24
CELL_HEIGHT :: 24

WINDOW_CELL_WIDTH :: 35
WINDOW_CELL_HEIGHT :: 35

CIRCLE_RAD :: 5

grid := [WINDOW_CELL_HEIGHT][WINDOW_CELL_WIDTH]int{}


main :: proc() {
	default := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default)
	defer mem.tracking_allocator_destroy(&tracking_allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)
	defer print_memory_usage(&tracking_allocator)

	rl.InitWindow(WINDOW_CELL_WIDTH * CELL_WIDTH, WINDOW_CELL_HEIGHT * CELL_HEIGHT, "dda impl")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	red_dot_pos := rl.Vector2{0, 0}

	for !rl.WindowShouldClose() {
		delta := rl.GetFrameTime()
		mouse := rl.GetMousePosition()

		if rl.IsKeyDown(.W) do red_dot_pos.y -= 200 * delta
		if rl.IsKeyDown(.A) do red_dot_pos.x -= 200 * delta
		if rl.IsKeyDown(.S) do red_dot_pos.y += 200 * delta
		if rl.IsKeyDown(.D) do red_dot_pos.x += 200 * delta

		if rl.IsMouseButtonDown(.LEFT) {
			x := int(mouse.x / CELL_WIDTH)
			y := int(mouse.y / CELL_HEIGHT)
			grid[y][x] = 1
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		for row, row_idx in grid {
			for cell, col_idx in row {
				if cell == 1 {
					rl.DrawRectangle(
						i32(col_idx * CELL_WIDTH),
						i32(row_idx * CELL_HEIGHT),
						CELL_WIDTH,
						CELL_HEIGHT,
						rl.BLUE,
					)
					rl.DrawRectangleLines(
						i32(col_idx * CELL_WIDTH),
						i32(row_idx * CELL_HEIGHT),
						CELL_WIDTH,
						CELL_HEIGHT,
						rl.WHITE,
					)
				} else {
					rl.DrawRectangleLines(
						i32(col_idx * CELL_WIDTH),
						i32(row_idx * CELL_HEIGHT),
						CELL_WIDTH,
						CELL_HEIGHT,
						rl.WHITE,
					)
				}
			}
		}

		rl.DrawCircleV(mouse, CIRCLE_RAD, rl.WHITE)

		rl.DrawCircleV(red_dot_pos, CIRCLE_RAD, rl.RED)

		rl.DrawLineV(red_dot_pos, mouse, rl.WHITE)

		rl.EndDrawing()
	}

}

print_memory_usage :: proc(tracking_allocator: ^mem.Tracking_Allocator, stats := false) {
	if stats {
		fmt.eprintfln("Total Allocated        : ", tracking_allocator.total_memory_allocated)
		fmt.eprintfln("Total Freed            : ", tracking_allocator.total_memory_freed)
		fmt.eprintfln("Total Allocation Count : ", tracking_allocator.total_free_count)
		fmt.eprintfln("Total Free Count       : ", tracking_allocator.total_free_count)
		fmt.eprintfln("Current Allocations    : ", tracking_allocator.current_memory_allocated)
		fmt.eprintln()
	}

	if len(tracking_allocator.allocation_map) > 0 {
		fmt.eprintln("Memory Leaks: ")
		for _, entry in tracking_allocator.allocation_map {
			fmt.eprintf(" - Leaked %d @ %v\n", entry.size, entry.location)
		}
	}

	if len(tracking_allocator.bad_free_array) > 0 {
		fmt.eprintln("Bad Frees: ")
		for entry in tracking_allocator.bad_free_array {
			fmt.eprintf(" - Bad Free %p @ %v\n", entry.memory, entry.location)
		}
	}
}
