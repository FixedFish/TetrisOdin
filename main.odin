package main

import rl "vendor:raylib"

main :: proc() {
	defer rl.CloseWindow()
	rl.InitWindow(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE, "TETRIS")
	rl.SetTargetFPS(60)

	game: Game
	init_grid(&game)
	fill_and_shuffle_bag(&game)

	for !(rl.WindowShouldClose()) {
		defer rl.EndDrawing()

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		handle_input(&game)
		generate_random_tetromino(&game)
		tetromino_fall(&game, rl.GetFrameTime())
		draw_grid(&game)
		draw_tetromino(&game)
	}
}
