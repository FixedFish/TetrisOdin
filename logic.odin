package main

import "core:math/rand"
import rl "vendor:raylib"

// 320x640 resolution
GRID_WIDTH: i32 : 20
GRID_HEIGHT: i32 : 10
CELL_SIZE: i32 : 32

FALL_INTERVAL: f32 = 0.4
FALL_TIMER: f32 = 0.0

Game :: struct {
	grid:                 [GRID_WIDTH][GRID_HEIGHT]GridCell,
	has_active_tetromino: bool,
	current_tetromino:    ^Tetromino,
	next_tetromino:       Tetromino,
	tetromino_bag:        [7]TetrominoType,
	bag_index:            i32,
}

GameState :: struct {
}

Vector2i :: struct {
	x, y: i32,
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

/* Grid logic */
init_grid :: proc(game: ^Game) {
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			game.grid[x][y].occupied = false
			game.grid[x][y].color = rl.DARKGRAY
		}
	}
}

/* Tetromino logic */

generate_random_tetromino :: proc(game: ^Game) {
	if !game.has_active_tetromino {
		if game.bag_index >= len(game.tetromino_bag) {
			fill_and_shuffle_bag(game)
		}
		new_ttype: TetrominoType = game.tetromino_bag[game.bag_index]
		game.bag_index += 1
		create_tetromino(new_ttype, game)
	}
}

create_tetromino :: proc(ttype: TetrominoType, game: ^Game) -> Tetromino {
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
		t.color = rl.MAGENTA
	case .L:
		t.blocks = {{0, 0}, {1, 0}, {0, -1}, {0, -2}}
		t.color = rl.ORANGE
	}
	t.position = {3, 0}
	game.has_active_tetromino = true
	game.current_tetromino = &t
	return t
}

tetromino_to_grid :: proc(t: ^Tetromino, game: ^Game) {
	for b in t.blocks {
		gx: i32 = t.position.x + b.x
		gy: i32 = t.position.y + b.y
		if (gx >= 0 && gx < GRID_WIDTH) && (gy >= 0 && gy < GRID_HEIGHT) {
			game.grid[gx][gy].occupied = true
			game.grid[gx][gy].color = t.color
		}
	}
	game.has_active_tetromino = false
}

move_tetramino :: proc(game: ^Game, delta: f32) {
	t: ^Tetromino = game^.current_tetromino
	FALL_TIMER += delta
	if FALL_TIMER >= FALL_INTERVAL {
		t.position.y += 1
		FALL_TIMER = 0
	}
}

/* Helper functions */
can_move :: proc() {}

is_valid_position :: proc() {}


fill_and_shuffle_bag :: proc(game: ^Game) {
	figures: [7]TetrominoType = {.I, .O, .T, .S, .Z, .J, .L}
	for i in 0 ..< len(figures) {
		game.tetromino_bag[i] = figures[i]
	}

	rand.shuffle(game.tetromino_bag[:])
	game.bag_index = 0
}
