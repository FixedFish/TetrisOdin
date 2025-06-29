package main

import "core:fmt"
import rl "vendor:raylib"

/* GameTex Renderer */
draw_grid :: proc(game: ^Game) {
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			cell: GridCell = game.grid[x][y]
			color: rl.Color = cell.color if cell.occupied else rl.DARKGRAY
			rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE - 1, CELL_SIZE - 1, color)
		}
	}
}

draw_tetromino :: proc(game: ^Game) {
	if !game.has_active_tetromino {return}
	t: Tetromino = game.current_tetromino
	for b in t.blocks {
		gx: i32 = (t.position.x + b.x) * CELL_SIZE
		gy: i32 = (t.position.y + b.y) * CELL_SIZE
		rl.DrawRectangle(gx, gy, CELL_SIZE - 1, CELL_SIZE - 1, t.color)
	}
}

draw_ghost_tetromino :: proc(game: ^Game) {
	if !game.has_active_tetromino {return}
	ghost_t: Tetromino = game.current_tetromino
	drop_pos := compute_drop_pos(game)
	ghost_t.position = drop_pos
	for b in ghost_t.blocks {
		gx: i32 = (ghost_t.position.x + b.x) * CELL_SIZE
		gy: i32 = (ghost_t.position.y + b.y) * CELL_SIZE
		rl.DrawRectangleLinesEx(
			rl.Rectangle{f32(gx), f32(gy), f32(CELL_SIZE - 1), f32(CELL_SIZE - 1)},
			2,
			ghost_t.color,
		)
	}
}

/* UITex Renderer */
draw_score :: proc(game: ^Game) {
	score := game.current_score
	text := rl.TextFormat("Score: %d", score)
	rl.DrawText(text, 15, 15, 25, rl.BLACK)
}

// Many magic numbers, should be totally refactored, but it works
draw_ui_grid :: proc(game: ^Game) {
	for x in 0 ..< 4 {
		for y in 0 ..< 4 {
			cell: GridCell = game.grid_ui[x][y]
			color: rl.Color = cell.color if cell.occupied else rl.DARKGRAY
			rl.DrawRectangle(i32((x * 16) + 214), i32((y * 16) + 48), 15, 15, color)
		}
	}
}

draw_ui_tetromino :: proc(game: ^Game) {
	t: Tetromino = game.next_tetromino
	for b in t.blocks {
		gx: i32 = (t.position.x + b.x) * 16
		gy: i32 = (t.position.y + b.y) * 16
		rl.DrawRectangle(gx + 160, gy + 80, 15, 15, t.color)
	}
}
