# [TIGR](https://github.com/erkkah/tigr) bindings for odin<br />

Installation (supports linux & windows, have not tested windows):
1. Clone this repo somewhere where you can import it (for example into Odin/shared)
2. Place your compiled tigr lib into this repositories directory (linux: "libtigr.a" /  windows: "tigr.lib")
3. import it in an odin project and use

Example:
```odin
package main

import "core:fmt"
import "core:time"

import mu "vendor:microui"

import "shared:tigr"

main :: proc() {
	screen := tigr.Window(640, 350, "tigr + odin + microui", {.Auto, ._2X}); defer tigr.Free(screen)

	mu_ctx := tigr.mur_init(screen)

	accum: f64
	start := time.tick_now()
	for !tigr.Closed(screen) {
		now := time.tick_now()
		dt := time.duration_seconds(time.tick_diff(start, now))
		start = now

		tigr.mur_handle_input()

		tigr.Clear(screen, tigr.rgb(0.4, 0.6, 0.4))

		@(static) text_buf: [4096]u8
		@(static) text_len: int
		@(static) num: f32
		@(static) num2: f32
		@(static) check: bool
		mu.begin(mu_ctx)
		if mu.window(mu_ctx, "Demo wim", {40, 40, 300, 200}) {
			if .ACTIVE in mu.header(mu_ctx, "Window Info") {
				win := mu.get_current_container(mu_ctx)
				mu.layout_row(mu_ctx, {54, -1})
				mu.label(mu_ctx, "Position:")
				mu.label(mu_ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))

				mu.layout_row(mu_ctx, {54, -1})
				mu.label(mu_ctx, "Size:")
				mu.label(mu_ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))

				mu.layout_row(mu_ctx, {-75, 70})
				mu.textbox(mu_ctx, text_buf[:], &text_len)
				if .SUBMIT in mu.button(mu_ctx, "Print text") {
					fmt.printfln("%s", text_buf[:text_len])
				}

				{
					mu.layout_row(mu_ctx, {-1})
					mu.layout_column(mu_ctx)
					mu.layout_row(mu_ctx, {-1})
					mu.slider(mu_ctx, &num, 0, 100)
					mu.layout_row(mu_ctx, {-1})
					mu.number(mu_ctx, &num2, 1)

					mu.checkbox(mu_ctx, "Toggle", &check)
				}
			}
		}
		mu.end(mu_ctx)

		tigr.mur_draw()

		tigr.Print(screen, tigr.tfont, 10, 10, tigr.rgb_u8(), "DT: %.4f / FPS: %.2f", dt, 1 / dt)
		tigr.Update(screen)

		free_all(context.temp_allocator)
	}
}
```

Known shortcomings:
* No clipboard support (so no get/set clipboard functions set nor Ctrl+(X/C/V))
* No select all text (Ctrl+A)
* No icons
... probably a couple of others.

Credits:
* [Odin raylib + microui example](https://pkg.odin-lang.org/examples/raylib/microui/) - helped in implementing the renderer
* [odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen) - really helped in generating bindings, tweaked a bit by hand as well
