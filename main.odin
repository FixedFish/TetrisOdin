package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

GRID_WIDTH: i32 : 8
GRID_HEIGHT: i32 : 12
CELL_SIZE: i32 : 32

grid: [GRID_WIDTH][GRID_HEIGHT]GridCell
fall_timer: f32 = 0.0
fall_interval: f32 : 0.4

has_active_tetromino: bool = false
current_tetromino: Tetromino
ttype: TetrominoType
previous_ttype: TetrominoType

tetromino_bag: [7]TetrominoType
bag_index: int = 7

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

TetrominoType :: enum {
	I,
	O,
	T,
	S,
	Z,
	J,
	L,
}

init_grid :: proc() {
	for y in 0 ..< GRID_HEIGHT {
		for x in 0 ..< GRID_WIDTH {
			grid[x][y].occupied = false
			grid[x][y].color = rl.DARKGRAY
		}
	}
}

generate_random_tetromino :: proc() -> Tetromino {
	if bag_index >= len(tetromino_bag) {
		fill_and_shuffle_bag()
	}

	new_ttype: TetrominoType = tetromino_bag[bag_index]
	bag_index += 1
	has_active_tetromino = true
	return create_tetromino(new_ttype)
}

create_tetromino :: proc(ttype: TetrominoType) -> Tetromino {
	t: Tetromino
	switch ttype {
	case .I:
		t.blocks = {{0, 0}, {0, -1}, {0, -2}, {0, -3}}
		t.color = rl.BLUE
	case .O:
		t.blocks = {{0, 0}, {1, 0}, {0, 1}, {1, 1}}
		t.color = rl.YELLOW
	case .T:
		t.blocks = {{-1, 0}, {0, 0}, {1, 0}, {0, 1}}
		t.color = rl.PINK
	case .S:
		t.blocks = {{-1, 0}, {0, 0}, {0, -1}, {1, -1}}
		t.color = rl.RED
	case .Z:
		t.blocks = {{0, 0}, {1, 0}, {0, -1}, {-1, -1}}
		t.color = rl.LIME
	case .J:
		t.blocks = {{-1, 0}, {0, 0}, {0, -1}, {0, -2}}
		t.color = rl.VIOLET
	case .L:
		t.blocks = {{0, 0}, {1, 0}, {0, -1}, {0, -2}}
		t.color = rl.ORANGE
	}
	t.position = {3, 0}
	return t
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

draw_tetromino :: proc(t: Tetromino) {
	if has_active_tetromino {
		for b in t.blocks {
			px: i32 = (t.position.x + b.x) * CELL_SIZE
			py: i32 = (t.position.y + b.y) * CELL_SIZE
			rl.DrawRectangle(px, py, CELL_SIZE - 1, CELL_SIZE - 1, t.color)
		}
	}
}

tetromino_to_grid :: proc(t: ^Tetromino) {
	for b in t.blocks {
		x: i32 = b.x + t.position.x
		y: i32 = b.y + t.position.y
		if y >= 0 && y < GRID_HEIGHT && x >= 0 && x < GRID_WIDTH {
			grid[x][y].occupied = true
			grid[x][y].color = t.color
		}
	}
	has_active_tetromino = false
}

can_move_down :: proc(t: ^Tetromino) -> bool {
	for b in t.blocks {
		gx: i32 = b.x + t.position.x
		gy: i32 = b.y + t.position.y + 1

		if gy >= 0 && (gy >= GRID_HEIGHT || grid[gx][gy].occupied) {
			return false
		}
	}
	return true
}

move_tetromino_down :: proc(t: ^Tetromino) {
	if has_active_tetromino {
		if can_move_down(t) {
			t.position.y += 1
		} else {
			tetromino_to_grid(t)
			clear_occupied_lines()
		}
	}
}

can_move_sideways :: proc(t: ^Tetromino, offset_x: i32) -> bool {
	for b in t.blocks {
		gx: i32 = b.x + t.position.x + offset_x
		gy: i32 = b.y + t.position.y

		if gx < 0 || gx >= GRID_WIDTH {
			return false
		}

		if gy >= 0 && gy < GRID_HEIGHT {
			if grid[gx][gy].occupied {
				return false
			}
		}
	}
	return true
}

clear_occupied_lines :: proc() {
	write_row: i32 = GRID_HEIGHT - 1

	for read_row := GRID_HEIGHT - 1; read_row >= 0; read_row -= 1 {
		is_line_full: bool = true
		for x in 0 ..< GRID_WIDTH {
			if !(grid[x][read_row].occupied) {
				is_line_full = false
				break
			}
		}
		if !is_line_full {
			copy_line(read_row, write_row)
			write_row -= 1
		}
	}
	for y in 0 ..< write_row {
		for x in 0 ..< GRID_WIDTH {
			grid[x][y].occupied = false
			grid[x][y].color = rl.DARKGRAY
		}
	}
}

copy_line :: proc(from_y, to_y: i32) {
	if from_y == to_y {
		return
	}
	for x in 0 ..< GRID_WIDTH {
		grid[x][to_y] = grid[x][from_y]
	}
}

handle_input :: proc(t: ^Tetromino) {
	if rl.IsKeyPressed(rl.KeyboardKey.A) {
		if can_move_sideways(t, -1) {
			t.position.x -= 1
		}
	}
	if rl.IsKeyPressed(rl.KeyboardKey.D) {
		if can_move_sideways(t, 1) {
			t.position.x += 1
		}
	}
	if rl.IsKeyPressed(rl.KeyboardKey.R) {
		restart_game()
	}
	if rl.IsKeyPressed(rl.KeyboardKey.W) {
		rotate_tetromino(t)
	}
}


/* TODO: 
handle_death :: proc(t: Tetromino) {
	for b in t.blocks {
		gx: i32 = b.x + t.position.x
		gy: i32 = b.y + t.position.y

		if gy >= 0 {
			if grid[gx][gy].occupied {
				restart_game()
			}
		}
	}
}  
*/

fill_and_shuffle_bag :: proc() {
	figures: [7]TetrominoType = {.I, .O, .T, .S, .Z, .J, .L}
	for i in 0 ..< len(figures) {
		tetromino_bag[i] = figures[i]
	}
	rand.shuffle(tetromino_bag[:])
	bag_index = 0
}

rotate_tetromino :: proc(t: ^Tetromino) {
	for &b in t.blocks {
		old_x := b.x
		old_y := b.y
		b.x = old_y
		b.y = -old_x
	}
}

restart_game :: proc() {
	for y in 0 ..< GRID_HEIGHT {
		for x in 0 ..< GRID_WIDTH {
			grid[x][y].occupied = false
			grid[x][y].color = rl.DARKGRAY
			has_active_tetromino = false
		}
	}
}

main :: proc() {
	defer rl.CloseWindow()
	rl.InitWindow(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE, "Tetris")
	rl.SetTargetFPS(60)

	init_grid()
	for !rl.WindowShouldClose() {
		defer rl.EndDrawing()
		dt := rl.GetFrameTime()
		fall_timer += dt

		if !(has_active_tetromino) {
			current_tetromino = generate_random_tetromino()
		}

		if fall_timer > fall_interval {
			fall_timer = 0.0
			move_tetromino_down(&current_tetromino)
		}
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		handle_input(&current_tetromino)
		// handle_death(current_tetromino)
		draw_grid()
		draw_tetromino(current_tetromino)
	}
}
