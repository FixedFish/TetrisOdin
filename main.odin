package main

import rl "vendor:raylib"

GRID_WIDTH: i32 : 10
GRID_HEIGHT: i32 : 20
CELL_SIZE: i32 : 32

grid: [GRID_WIDTH][GRID_HEIGHT]GridCell
fall_timer: f32 = 0.0
fall_interval: f32 : 0.5

Vector2i :: struct {
	x: i32,
	y: i32,
}

GridCell :: struct {
	occupied: bool,
	color:    rl.Color,
}

Tetromino :: struct {
	blocks:   [4]Vector2i,
	position: Vector2i,
	color:    rl.Color,
}

init_grid :: proc() {
	for y in 0 ..< GRID_HEIGHT {
		for x in 0 ..< GRID_WIDTH {
			grid[x][y].occupied = false
			grid[x][y].color = rl.DARKGRAY
		}
	}
}

create_tetromino :: proc() -> Tetromino {
	return Tetromino {
		blocks = {Vector2i{0, 0}, Vector2i{1, 0}, Vector2i{2, 0}, Vector2i{3, 0}},
		position = Vector2i{3, 0},
		color = rl.SKYBLUE,
	}
}

draw_grid :: proc() {
	for y in 0 ..< GRID_HEIGHT {
		for x in 0 ..< GRID_WIDTH {
			cell: GridCell = grid[x][y]
			color: rl.Color = cell.color if cell.occupied else rl.RAYWHITE
			rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE - 1, CELL_SIZE - 1, color)
		}
	}
}

// TODO: Rewrite this, implement simple collision check with other tetramino and also stop on GRID_HEIGHT - 1
draw_tetramino :: proc(t: Tetromino) {
	for b in t.blocks {
		if t.position.y < GRID_HEIGHT - 9 {
			px: i32 = (t.position.x + b.x) * CELL_SIZE
			py: i32 = (t.position.y + b.y) * CELL_SIZE
			rl.DrawRectangle(px, py, CELL_SIZE - 1, CELL_SIZE - 1, t.color)
		}
	}
}

move_tetramino_down :: proc(t: ^Tetromino) {
	t.position.y += 1
}

main :: proc() {
	defer rl.CloseWindow()
	rl.InitWindow(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE, "Tetris")
	rl.SetTargetFPS(60)

	init_grid()
	current := create_tetromino()

	for !rl.WindowShouldClose() {
		defer rl.EndDrawing()
		dt := rl.GetFrameTime()
		fall_timer += dt

		if fall_timer > 1.0 {
			fall_timer = 0.0
			move_tetramino_down(&current)
		}
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_grid()
		draw_tetramino(current)
	}
}
