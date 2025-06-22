package main

import rl "vendor:raylib"

main :: proc() {
	defer rl.CloseWindow()
	rl.InitWindow(320, 800, "TETRIS")
	rl.SetTargetFPS(60)

	game_tex := rl.LoadRenderTexture(320, 640)
	ui_tex := rl.LoadRenderTexture(320, 160)

	game: Game
	game.state = .Playing
	init_grid(&game)
	fill_and_shuffle_bag(&game)

	generate_random_tetromino(&game)
	spawn_next_tetromino(&game)

	defer rl.UnloadRenderTexture(game_tex)
	defer rl.UnloadRenderTexture(ui_tex)

	for !(rl.WindowShouldClose()) {

		// Game
		rl.BeginTextureMode(game_tex)
		rl.ClearBackground(rl.RAYWHITE)
		if game.state == .GameOver {
			restart_game(&game)
		}
		handle_input(&game)
		tetromino_fall(&game, rl.GetFrameTime())
		draw_grid(&game)
		draw_ghost_tetromino(&game)
		draw_tetromino(&game)
		rl.EndTextureMode()

		// UI
		rl.BeginTextureMode(ui_tex)
		rl.ClearBackground(rl.MAROON)
		draw_score(&game)
		draw_ui_grid(&game)
		draw_ui_tetromino(&game)
		rl.EndTextureMode()

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTextureRec(
			game_tex.texture,
			rl.Rectangle{0, 0, 320, -640},
			rl.Vector2{0, 160},
			rl.WHITE,
		)
		rl.DrawTextureRec(
			ui_tex.texture,
			rl.Rectangle{0, 0, 320, -160},
			rl.Vector2{0, 0},
			rl.WHITE,
		)
		rl.EndDrawing()
	}
}
