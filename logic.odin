package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

// 320x640 resolution
GRID_WIDTH: i32 : 10
GRID_HEIGHT: i32 : 20
CELL_SIZE: i32 : 32

FALL_INTERVAL: f32 = 0.5

Game :: struct {
	grid:                 [GRID_WIDTH][GRID_HEIGHT]GridCell,
	has_active_tetromino: bool,
	current_tetromino:    Tetromino,
	next_tetromino:       Tetromino,
	tetromino_bag:        [7]TetrominoType,
	bag_index:            i32,
	fall_timer:           f32,
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
	state:    TetrominoState,
	type:     TetrominoType,
}

TetrominoState :: enum {
	Spawn, // 0
	Right, // R
	Left, // L
	Flip, // 2
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

JLSTZ_WALL_KICK_DATA: [8][5]Vector2i = {
	// Spawn -> Right
	{{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
	// Right -> Spawn 
	{{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
	// Right -> Flip
	{{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
	// Flip -> Right
	{{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
	// Flip -> Left
	{{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
	// Left -> Flip
	{{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
	// Left -> Spawn
	{{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
	// Spawn -> Left
	{{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
}

I_WALL_KICK_DATA: [8][5]Vector2i = {
	// Spawn -> Right
	{{0, 0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2}},
	// Right -> Spawn
	{{0, 0}, {2, 0}, {-1, 0}, {2, -1}, {-1, 2}},
	// Right -> Flip
	{{0, 0}, {-1, 0}, {2, 0}, {-1, -2}, {2, 1}},
	// Flip -> Right
	{{0, 0}, {1, 0}, {-2, 0}, {1, 2}, {-2, -1}},
	// Flip -> Left
	{{0, 0}, {2, 0}, {-1, 0}, {2, -1}, {-1, 2}},
	// Left -> Flip
	{{0, 0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2}},
	// Left -> Spawn
	{{0, 0}, {1, 0}, {-2, 0}, {1, 2}, {-2, -1}},
	// Spawn -> Left
	{{0, 0}, {-1, 0}, {2, 0}, {-1, -2}, {2, 1}},
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

create_tetromino :: proc(ttype: TetrominoType, game: ^Game) {
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
	t.position = {GRID_WIDTH / 2, 0}
	t.type = ttype
	t.state = .Spawn
	game.has_active_tetromino = true
	game.current_tetromino = t
}

tetromino_to_grid :: proc(game: ^Game) {
	t: Tetromino = game.current_tetromino
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

tetromino_fall :: proc(game: ^Game, delta: f32) {
	game.fall_timer += delta
	if game.fall_timer < FALL_INTERVAL {return}
	game.fall_timer = 0

	if can_move(game, 0, 1) {
		game.current_tetromino.position.y += 1
	} else {
		tetromino_to_grid(game)
		check_and_clean_lines(game)
	}
}

rotate_tetromino :: proc(game: ^Game, clockwise: bool) {
	if game.current_tetromino.type == .O {return}

	from_state: TetrominoState = game.current_tetromino.state
	to_state: TetrominoState
	kick_index: i32

	if clockwise {
		to_state = TetrominoState(int(from_state) % 4)

		switch from_state {
		case .Spawn:
			kick_index = 0
		case .Right:
			kick_index = 2
		case .Left:
			kick_index = 6
		case .Flip:
			kick_index = 4
		}
	} else {
		to_state = TetrominoState(int(from_state) % 4)
		switch from_state {
		case .Spawn:
			kick_index = 7
		case .Right:
			kick_index = 1
		case .Left:
			kick_index = 5
		case .Flip:
			kick_index = 3
		}
	}

	kick_table: ^[8][5]Vector2i
	if game.current_tetromino.type == .I {
		kick_table = &I_WALL_KICK_DATA
	} else {
		kick_table = &JLSTZ_WALL_KICK_DATA
	}

	ghost_tetromino := game.current_tetromino
	if clockwise {
		for i in 0 ..< len(ghost_tetromino.blocks) {
			old_x := ghost_tetromino.blocks[i].x
			ghost_tetromino.blocks[i].x = ghost_tetromino.blocks[i].y
			ghost_tetromino.blocks[i].y = -old_x
		}
	} else {
		for i in 0 ..< len(ghost_tetromino.blocks) {
			old_y := ghost_tetromino.blocks[i].y
			ghost_tetromino.blocks[i].y = ghost_tetromino.blocks[i].x
			ghost_tetromino.blocks[i].x = -old_y
		}
	}

	for i in 0 ..< 5 {
		offset := kick_table[kick_index][i]
		ghost_tetromino.position.x += offset.x
		ghost_tetromino.position.y += offset.y

		if is_valid_state(game, ghost_tetromino) {
			game.current_tetromino.blocks = ghost_tetromino.blocks
			game.current_tetromino.position = ghost_tetromino.position
			game.current_tetromino.state = to_state
			return
		}
	}
}

/* Input logic */
// TODO: Refactor needed
handle_input :: proc(game: ^Game) {
	if rl.IsKeyPressed(rl.KeyboardKey.A) {
		if can_move(game, -1, 0) {
			game.current_tetromino.position.x -= 1
		}
	}
	if rl.IsKeyPressed(rl.KeyboardKey.D) {
		if can_move(game, 1, 0) {
			game.current_tetromino.position.x += 1
		}
	}
	if rl.IsKeyPressed(rl.KeyboardKey.W) {
		rotate_tetromino(game, true)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.S) {
		rotate_tetromino(game, false)
	}
}

/* Helper functions */
can_move :: proc(game: ^Game, offset_x, offset_y: i32) -> bool {
	ghost_tetromino := game.current_tetromino
	ghost_tetromino.position.x += offset_x
	ghost_tetromino.position.y += offset_y

	if is_valid_state(game, ghost_tetromino) {return true} else {return false}
}

is_valid_grid_pos :: proc(game: ^Game, pos: Vector2i) -> bool {
	if pos.x < 0 || pos.x >= GRID_WIDTH {return false}
	if pos.y >= GRID_HEIGHT {return false}

	if pos.y < 0 {return true}

	return !game.grid[pos.x][pos.y].occupied
}

is_valid_state :: proc(game: ^Game, t: Tetromino) -> bool {
	for b in t.blocks {
		absolute_pos: Vector2i = Vector2i {
			x = t.position.x + b.x,
			y = t.position.y + b.y,
		}

		if !is_valid_grid_pos(game, absolute_pos) {
			return false
		}
	}
	return true
}

check_and_clean_lines :: proc(game: ^Game) {
	write_y := GRID_HEIGHT - 1
	for read_y := GRID_HEIGHT - 1; read_y >= 0; read_y -= 1 {
		if !is_line_full(game, read_y) {
			for x in 0 ..< GRID_WIDTH {
				game.grid[x][write_y] = game.grid[x][read_y]
			}
			write_y -= 1
		}
	}
	for y := write_y; y >= 0; y -= 1 {
		clean_line(game, y)
	}
}

clean_line :: proc(game: ^Game, line: i32) {
	for x in 0 ..< GRID_WIDTH {
		game.grid[x][line].occupied = false
	}
}

is_line_full :: proc(game: ^Game, line: i32) -> bool {
	grid := game.grid
	for x in 0 ..< GRID_WIDTH {
		if !(grid[x][line].occupied) {
			return false
		}
	}
	return true
}

fill_and_shuffle_bag :: proc(game: ^Game) {
	figures: [7]TetrominoType = {.I, .O, .T, .S, .Z, .J, .L}
	for i in 0 ..< len(figures) {
		game.tetromino_bag[i] = figures[i]
	}

	rand.shuffle(game.tetromino_bag[:])
	game.bag_index = 0
}

print_absolute_position :: proc(game: ^Game) {
	t: Tetromino = game.current_tetromino
	for b in t.blocks {
		gx: i32 = t.position.x + b.x
		gy: i32 = t.position.y + b.y
		fmt.println("X: {}, Y: {}", gx, gy)
	}
}
