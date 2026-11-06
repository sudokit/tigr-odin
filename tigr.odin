// TIGR - TIny GRaphics Library - v3.2
//        ^^   ^^
//
// rawr.

/*
This is free and unencumbered software released into the public domain.

Our intent is that anyone is free to copy and use this software,
for any purpose, in any form, and by any means.

The authors dedicate any and all copyright interest in the software
to the public domain, at their own expense for the betterment of mankind.

The software is provided "as is", without any kind of warranty, including
any implied warranty. If it breaks, you get to keep both pieces.
*/
package tigr

@(extra_linker_flags = "-lGLU -lGL -lX11")
foreign import lib "./libtigr.a"

// This struct contains one pixel.
Pixel :: [4]u8

// Window flags.
Window_Flag :: enum i32 {
	Auto       = 0, // window's bitmap is scaled with the window
	_2X        = 1, // always enforce (at least) 2X pixel scale
	_3X        = 2, // always enforce (at least) 3X pixel scale
	_4X        = 3, // always enforce (at least) 4X pixel scale
	Retina     = 4, // enable retina support on OS X
	NoCursor   = 5, // hide cursor
	Fullscreen = 6, // start in full-screen mode
}
Window_Flags :: bit_set[Window_Flag;i32]


// A Tigr bitmap.
Tigr :: struct {
	w, h:           i32, // width/height (unscaled)
	cx, cy, cw, ch: i32, // clip rect
	pix:            ^Pixel, // pixel data
	handle:         rawptr, // OS window handle, NULL for off-screen bitmaps.
	blitMode:       i32, // Target bitmap blit mode
}

@(default_calling_convention = "c", link_prefix = "tigr")
foreign lib {
	// Creates a new empty window with a given bitmap size.
	//
	// Title is UTF-8.
	//
	// In TIGR_FIXED mode, the window is made as large as possible to contain an integer-scaled
	// version of the bitmap while still fitting on the screen. Resizing the window will adapt
	// the scale in integer steps to fit the bitmap.
	//
	// In TIGR_AUTO mode, the initial window size is set to the bitmap size times the pixel
	// scale. Resizing the window will resize the bitmap using the specified scale.
	// For example, in forced 2X mode, the window will be twice as wide (and high) as the bitmap.
	//
	// Turning on TIGR_RETINA mode will request full backing resolution on OSX, meaning that
	// the effective window size might be integer scaled to a larger size. In TIGR_AUTO mode,
	// this means that the Tigr bitmap will change size if the window is moved between
	// retina and non-retina screens.
	//
	Window :: proc(w: i32, h: i32, title: cstring, flags: Window_Flags = {}) -> ^Tigr ---

	// Creates an empty off-screen bitmap.
	Bitmap :: proc(w: i32, h: i32) -> ^Tigr ---

	// Deletes a window/bitmap.
	Free :: proc(bmp: ^Tigr) ---

	// Returns non-zero if the user requested to close a window.
	Closed :: proc(bmp: ^Tigr) -> bool ---

	// Displays a window's contents on-screen and updates input.
	Update :: proc(bmp: ^Tigr) ---

	// Called before doing direct OpenGL calls and before tigrUpdate.
	// Returns non-zero if OpenGL is available.
	BeginOpenGL :: proc(bmp: ^Tigr) -> bool ---

	// Sets post shader for a window.
	// This replaces the built-in post-FX shader.
	SetPostShader :: proc(bmp: ^Tigr, code: cstring, size: i32) ---

	// Sets post-FX properties for a window.
	//
	// The built-in post-FX shader uses the following parameters:
	// p1: hblur - use bilinear filtering along the x-axis (pixels)
	// p2: vblur - use bilinear filtering along the y-axis (pixels)
	// p3: scanlines - CRT scanlines effect (0-1)
	// p4: contrast - contrast boost (1 = no change, 2 = 2X contrast, etc)
	SetPostFX :: proc(bmp: ^Tigr, p1: f32, p2: f32, p3: f32, p4: f32) ---

	// Helper for reading pixels.
	// For high performance, just access bmp->pix directly.
	Get :: proc(bmp: ^Tigr, x: i32, y: i32) -> Pixel ---

	// Plots a pixel.
	// Clips and blends.
	// For high performance, just access bmp->pix directly.
	Plot :: proc(bmp: ^Tigr, x: i32, y: i32, pix: Pixel) ---

	// Clears a bitmap to a color.
	// No blending, no clipping.
	Clear :: proc(bmp: ^Tigr, color: Pixel) ---

	// Fills a rectangular area.
	// No blending, no clipping.
	Fill :: proc(bmp: ^Tigr, x: i32, y: i32, w: i32, h: i32, color: Pixel) ---

	// Draws a line.
	// Start pixel is drawn, end pixel is not.
	// Clips and blends.
	Line :: proc(bmp: ^Tigr, x0: i32, y0: i32, x1: i32, y1: i32, color: Pixel) ---

	// Draws an empty rectangle.
	// Drawing a 1x1 rectangle yields the same result as calling tigrPlot.
	// Clips and blends.
	Rect :: proc(bmp: ^Tigr, x: i32, y: i32, w: i32, h: i32, color: Pixel) ---

	// Fills a rectangle.
	// Fills the inside of the specified rectangular area.
	// Calling tigrRect followed by tigrFillRect using the same arguments
	// causes no overdrawing.
	// Clips and blends.
	FillRect :: proc(bmp: ^Tigr, x: i32, y: i32, w: i32, h: i32, color: Pixel) ---

	// Draws a circle.
	// Drawing a zero radius circle yields the same result as calling tigrPlot.
	// Drawing a circle with radius one draws a circle three pixels wide.
	// Clips and blends.
	Circle :: proc(bmp: ^Tigr, x: i32, y: i32, r: i32, color: Pixel) ---

	// Fills a circle.
	// Fills the inside of the specified circle.
	// Calling tigrCircle followed by tigrFillCircle using the same arguments
	// causes no overdrawing.
	// Filling a circle with zero radius has no effect.
	// Clips and blends.
	FillCircle :: proc(bmp: ^Tigr, x: i32, y: i32, r: i32, color: Pixel) ---

	// Sets clip rect.
	// Set to (0, 0, -1, -1) to reset clipping to full bitmap.
	Clip :: proc(bmp: ^Tigr, cx: i32, cy: i32, cw: i32, ch: i32) ---

	// Copies bitmap data.
	// dx/dy = dest co-ordinates
	// sx/sy = source co-ordinates
	// w/h   = width/height
	//
	// RGBAdest = RGBAsrc
	// Clips, does not blend.
	Blit :: proc(dest: ^Tigr, src: ^Tigr, dx: i32, dy: i32, sx: i32, sy: i32, w: i32, h: i32) ---

	// Same as tigrBlit, but alpha blends the source bitmap with the
	// target using per pixel alpha and the specified global alpha.
	//
	// Ablend = Asrc * alpha
	// RGBdest = RGBsrc * Ablend + RGBdest * (1 - Ablend)
	//
	// Blit mode == TIGR_KEEP_ALPHA:
	// Adest = Adest
	//
	// Blit mode == TIGR_BLEND_ALPHA:
	// Adest = Asrc * Ablend + Adest * (1 - Ablend)
	// Clips and blends.
	BlitAlpha :: proc(dest: ^Tigr, src: ^Tigr, dx: i32, dy: i32, sx: i32, sy: i32, w: i32, h: i32, alpha: f32) ---

	// Same as tigrBlit, but tints the source bitmap with a color
	// and alpha blends the resulting source with the destination.
	//
	// Rblend = Rsrc * Rtint
	// Gblend = Gsrc * Gtint
	// Bblend = Bsrc * Btint
	// Ablend = Asrc * Atint
	//
	// RGBdest = RGBblend * Ablend + RGBdest * (1 - Ablend)
	//
	// Blit mode == TIGR_KEEP_ALPHA:
	// Adest = Adest
	//
	// Blit mode == TIGR_BLEND_ALPHA:
	// Adest = Ablend * Ablend + Adest * (1 - Ablend)
	// Clips and blends.
	BlitTint :: proc(dest: ^Tigr, src: ^Tigr, dx: i32, dy: i32, sx: i32, sy: i32, w: i32, h: i32, tint: Pixel) ---
}

Blit_Mode :: enum i32 {
	Keep_Alpha  = 0, // Keep destination alpha value
	Blend_Alpha = 1, // Blend destination alpha (default)
}

@(default_calling_convention = "c", link_prefix = "tigr")
foreign lib {
	// Set destination bitmap blend mode for blit operations.
	BlitMode :: proc(dest: ^Tigr, mode: Blit_Mode) ---
}

// Font printing ----------------------------------------------------------
Glyph :: struct {
	code, x, y, w, h: i32,
}

Font :: struct {
	bitmap:    ^Tigr,
	numGlyphs: i32,
	glyphs:    ^Glyph,
}

// builtin font
@(link_name = "tfont")
tfont: ^Font

Codepage :: enum i32 {
	Ascii = 0,
	_1252 = 1252,
	UTF32 = 12001,
}

@(default_calling_convention = "c", link_prefix = "tigr")
foreign lib {
	// Loads a font from a bitmap font sheet.
	// The loaded font takes ownership of the provided bitmap.
	//
	// Codepages:
	//
	//  TCP_ASCII   - Regular 7-bit ASCII
	//  TCP_1252    - Windows 1252
	//  TCP_UTF32   - Unicode subset
	//
	// For ASCII and 1252, the font bitmap should contain all characters
	// for the given codepage, excluding the first 32 control codes.
	//
	// For UTF32 - the font bitmap contains a subset of Unicode characters
	// and must be in the format generated by tigrFont for UTF32.
	//
	LoadFont :: proc(bitmap: ^Tigr, codepage: Codepage) -> ^Font ---

	// Frees a font and associated font sheet.
	FreeFont :: proc(font: ^Font) ---

	// Prints UTF-8 text onto a bitmap.
	// NOTE:
	//  This uses the target bitmap blit mode.
	//  See tigrBlitTint for details.
	Print :: proc(dest: ^Tigr, font: ^Font, x: i32, y: i32, color: Pixel, text: cstring, #c_vararg _: ..any) ---

	// Returns the width/height of a string.
	TextWidth :: proc(font: ^Font, text: cstring) -> i32 ---
	TextHeight :: proc(font: ^Font, text: cstring) -> i32 ---
}

// Key scancodes. For letters/numbers, use ASCII ('A'-'Z' and '0'-'9').
Key :: enum u32 {
	Pad0      = 128,
	Pad1      = 129,
	Pad2      = 130,
	Pad3      = 131,
	Pad4      = 132,
	Pad5      = 133,
	Pad6      = 134,
	Pad7      = 135,
	Pad8      = 136,
	Pad9      = 137,
	Padmul    = 138,
	Padadd    = 139,
	Padenter  = 140,
	Padsub    = 141,
	Paddot    = 142,
	Paddiv    = 143,
	F1        = 144,
	F2        = 145,
	F3        = 146,
	F4        = 147,
	F5        = 148,
	F6        = 149,
	F7        = 150,
	F8        = 151,
	F9        = 152,
	F10       = 153,
	F11       = 154,
	F12       = 155,
	Backspace = 156,
	Tab       = 157,
	Return    = 158,
	Shift     = 159,
	Control   = 160,
	Alt       = 161,
	Pause     = 162,
	Capslock  = 163,
	Escape    = 164,
	Space     = 165,
	Pageup    = 166,
	Pagedn    = 167,
	End       = 168,
	Home      = 169,
	Left      = 170,
	Up        = 171,
	Right     = 172,
	Down      = 173,
	Insert    = 174,
	Delete    = 175,
	Lwin      = 176,
	Rwin      = 177,
	Numlock   = 178,
	Scroll    = 179,
	Lshift    = 180,
	Rshift    = 181,
	Lcontrol  = 182,
	Rcontrol  = 183,
	Lalt      = 184,
	Ralt      = 185,
	Semicolon = 186,
	Equals    = 187,
	Comma     = 188,
	Minus     = 189,
	Dot       = 190,
	Slash     = 191,
	Backtick  = 192,
	Lsquare   = 193,
	Backslash = 194,
	Rsquare   = 195,
	Tick      = 196,
}

@(default_calling_convention = "c", link_prefix = "tigr")
foreign lib {
	// Returns mouse input for a window.
	// The value set to "buttons" is a bit set where bits 0, 1 and 2
	// corresponds to the left, right and middle buttons.
	// A set bit indicates that a button is held.
	Mouse :: proc(bmp: ^Tigr, x: ^i32, y: ^i32, buttons: ^i32) ---
}

Touch_Point :: [2]i32

@(default_calling_convention = "c", link_prefix = "tigr")
foreign lib {
	// Reads touch input for a window.
	// Returns number of touch points read.
	Touch :: proc(bmp: ^Tigr, points: ^Touch_Point, maxPoints: i32) -> i32 ---

	// Reads the delta of the scroll "wheel" in somewhat platform neutral
	// units where 1.0 corresponds to a "notch". The actual correlation between
	// physical movement and this number varies between platforms, input methods
	// and settings.
	ScrollWheel :: proc(bmp: ^Tigr, x: ^f32, y: ^f32) ---

	// Reads the keyboard for a window.
	// Returns non-zero if a key is pressed/held.
	// tigrKeyDown tests for the initial press, tigrKeyHeld repeats each frame.
	KeyDown :: proc(bmp: ^Tigr, key: Key) -> bool ---
	KeyHeld :: proc(bmp: ^Tigr, key: Key) -> bool ---

	// Reads character input for a window.
	// Returns the Unicode value of the last key pressed, or 0 if none.
	ReadChar :: proc(bmp: ^Tigr) -> u8 ---

	// Show / hide virtual keyboard.
	// (Only available on iOS / Android)
	ShowKeyboard :: proc(show: i32) ---

	// Loads a PNG, from either a file or memory. (fileName is UTF-8)
	// On error, returns NULL and sets errno.
	LoadImage :: proc(fileName: cstring) -> ^Tigr ---
	LoadImageMem :: proc(data: rawptr, length: i32) -> ^Tigr ---

	// Saves a PNG to a file. (fileName is UTF-8)
	// On error, returns zero and sets errno.
	SaveImage :: proc(fileName: cstring, bmp: ^Tigr) -> bool ---

	// Returns the amount of time elapsed since tigrTime was last called,
	// or zero on the first call.
	Time :: proc() -> f32 ---

	// Displays an error message and quits. (UTF-8)
	// 'bmp' can be NULL.
	Error :: proc(bmp: ^Tigr, message: cstring, #c_vararg _: ..any) ---

	// Reads an entire file into memory. (fileName is UTF-8)
	// Free it yourself after with 'free'.
	// On error, returns NULL and sets errno.
	// TIGR will automatically append a NUL terminator byte
	// to the end (not included in the length)
	ReadFile :: proc(fileName: cstring, length: ^i32) -> rawptr ---

	// Decompresses DEFLATEd zip/zlib data into a buffer.
	// Returns non-zero on success.
	Inflate :: proc(out: rawptr, outlen: u32, _in: rawptr, inlen: u32) -> bool ---

	// Decodes a single UTF8 codepoint and returns the next pointer.
	DecodeUTF8 :: proc(text: cstring, cp: ^i32) -> cstring ---

	// Encodes a single UTF8 codepoint and returns the next pointer.
	EncodeUTF8 :: proc(text: cstring, cp: i32) -> cstring ---
}

rgb_u8 :: #force_inline proc(r: u8 = 255, g: u8 = 255, b: u8 = 255) -> Pixel {return {
		r,
		g,
		b,
		0xff,
	}}

rgba_u8 :: #force_inline proc(
	r: u8 = 255,
	g: u8 = 255,
	b: u8 = 255,
	a: u8 = 255,
) -> Pixel {return {r, g, b, a}}

rgb_f32 :: #force_inline proc(r: f32 = 1.0, g: f32 = 1.0, b: f32 = 1.0) -> Pixel {return {
		u8(r * 255),
		u8(g * 255),
		u8(b * 255),
		0xff,
	}}

rgba_f32 :: #force_inline proc(
	r: f32 = 1.0,
	g: f32 = 1.0,
	b: f32 = 1.0,
	a: f32 = 1.0,
) -> Pixel {return {u8(r * 255), u8(g * 255), u8(b * 255), u8(a * 255)}}

rgb :: proc {
	rgb_u8,
	rgb_f32,
}
rgba :: proc {
	rgba_u8,
	rgba_f32,
}
