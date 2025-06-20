package main

import "core:fmt"
import rl "vendor:raylib"
/* Grid Render */
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
