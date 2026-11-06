package tigr

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

import mu "vendor:microui"

@(private = "file")
tigr_microui_key_map := #partial [mu.Key]Key {
	.SHIFT     = .Shift,
	.CTRL      = .Control,
	.ALT       = .Alt,
	.BACKSPACE = .Backspace,
	.DELETE    = .Delete,
	.RETURN    = .Return,
	.LEFT      = .Left,
	.RIGHT     = .Right,
	.HOME      = .Home,
	.END       = .End,
}

@(private = "file")
s: struct {
	mu_ctx:            mu.Context,
	screen:            ^Tigr,
	_tigr_font_height: i32,
	clip_rect:         [4]i32,
	atlas:             ^Tigr,
}

mur_init :: proc(screen: ^Tigr) -> ^mu.Context {
	s._tigr_font_height = TextHeight(tfont, "M")
	s.screen = screen

	s.atlas = Bitmap(mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT)

	for alpha, i in mu.default_atlas_alpha {
		x := i % mu.DEFAULT_ATLAS_WIDTH
		y := i / mu.DEFAULT_ATLAS_WIDTH
		color := rgba_u8(255, 255, 255, alpha)
		Plot(s.atlas, i32(x), i32(y), color)
	}

	ctx := &s.mu_ctx
	mu.init(ctx)
	ctx.style.font = mu.Font(tfont)
	ctx.text_width = proc(font: mu.Font, str: string) -> i32 {
		tigr_font := cast(^Font)font
		if tigr_font == nil do tigr_font = tfont
		return TextWidth(tigr_font, strings.clone_to_cstring(str, context.temp_allocator))
	}
	ctx.text_height = proc(font: mu.Font) -> i32 {
		tigr_font := cast(^Font)font
		if tigr_font == nil do tigr_font = tfont
		return TextHeight(tigr_font, "M")
	}
	return ctx
}

mur_deinit :: proc() {
	Free(s.atlas)
}

mur_handle_input :: proc() {
	@(static) last_buttons: i32
	@(static) last_keys: [mu.Key]bool

	ctx := &s.mu_ctx

	mpos, button_state := get_mouse(s.screen)
	mu.input_mouse_move(ctx, mpos.x, mpos.y)

	left, middle, right := decode_mouse_button_state(button_state)
	lf_left, lf_middle, lf_right := decode_mouse_button_state(last_buttons)
	last_buttons = button_state

	mouse_button(ctx, mpos, .LEFT, left, lf_left)
	mouse_button(ctx, mpos, .MIDDLE, middle, lf_middle)
	mouse_button(ctx, mpos, .RIGHT, right, lf_right)

	scroll_x, scroll_y: f32
	ScrollWheel(s.screen, &scroll_x, &scroll_y)
	if scroll_x != 0 || scroll_y != 0 {
		mu.input_scroll(ctx, i32(scroll_x), i32(-scroll_y))
	}

	c := ReadChar(s.screen)
	if c != 0 && c >= 32 && c != 127 {
		b, w := utf8.encode_rune(rune(c))
		mu.input_text(ctx, string(b[:w]))
	}

	for tigr_key, mu_key in tigr_microui_key_map {
		if tigr_key == {} do continue
		down := bool(KeyHeld(s.screen, tigr_key))
		if down && !last_keys[mu_key] {
			mu.input_key_down(ctx, mu_key)
		} else if !down && last_keys[mu_key] {
			mu.input_key_up(ctx, mu_key)
		}
		last_keys[mu_key] = down
	}
}

mur_draw :: proc() {
	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(&s.mu_ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Clip:
			clip_r := cmd.rect
			x0 := max(clip_r.x, 0)
			y0 := max(clip_r.y, 0)
			x1 := min(clip_r.x + clip_r.w, s.screen.w)
			y1 := min(clip_r.y + clip_r.h, s.screen.h)
			if x1 < x0 do x1 = x0
			if y1 < y0 do y1 = y0
			Clip(s.screen, x0, y0, x1 - x0, y1 - y0)
		case ^mu.Command_Rect:
			r := cmd.rect
			Fill(s.screen, r.x, r.y, r.w, r.h, {**cmd.color})
		case ^mu.Command_Text:
			pos := cmd.pos
			Print(
				s.screen,
				tfont,
				pos.x,
				pos.y,
				{**cmd.color},
				"%s",
				strings.clone_to_cstring(cmd.str, context.temp_allocator),
			)
		case ^mu.Command_Icon:
			src := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - src.w) / 2
			y := cmd.rect.y + (cmd.rect.h - src.h) / 2
			BlitTint(s.screen, s.atlas, x, y, src.x, src.y, src.w, src.h, {**cmd.color})

		case ^mu.Command_Jump:
			unreachable()
		}
	}

	Clip(s.screen, 0, 0, -1, -1)
}

// utils
@(private = "file")
get_mouse :: proc(screen: ^Tigr) -> (pos: [2]i32, button_state: i32) {
	Mouse(screen, &pos.x, &pos.y, &button_state)
	return
}

@(private = "file")
decode_mouse_button_state :: proc(buttons: i32) -> (left, middle, right: bool) {
	return (buttons & 1) != 0, (buttons & 2) != 0, (buttons & 4) != 0
}

@(private = "file")
mouse_button :: proc(ctx: ^mu.Context, pos: [2]i32, btn: mu.Mouse, now, prev: bool) {
	if now && !prev {
		mu.input_mouse_down(ctx, pos.x, pos.y, btn)
	} else if !now && prev {
		mu.input_mouse_up(ctx, pos.x, pos.y, btn)
	}
}
