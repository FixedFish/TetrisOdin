package main

import rl "vendor:raylib"

main :: proc() {
	defer rl.CloseWindow()
	rl.InitWindow(320, 640, "TETRIS")
	rl.SetTargetFPS(60)

	for !(rl.WindowShouldClose()) {
		defer rl.EndDrawing()
		game: Game = Game{}
		init_grid(&game)

		rl.BeginDrawing()
		enerate_random_tetromino(&game)
		move_tetramino(&game, rl.GetFrameTime())
		draw_grid(&game)
		draw_tetromino(&game)
	}
}
