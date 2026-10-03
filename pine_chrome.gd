class_name PineChrome


extends RefCounted

const avance := 0.62
const bloques := 12
const patron := [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2]

const rutas := [
	"res://fonts/PressStart2P-Regular.ttf",
	"C:/Windows/Fonts/consola.ttf",
	"C:/Windows/Fonts/cour.ttf",
	"C:/Windows/Fonts/lucon.ttf",
]

var borde := Color(0.82, 0.82, 0.82)
var tinta := Color(0.86, 0.86, 0.86)
var titulo := Color(0.30, 1.0, 0.34)
var fondo := Color(0.02, 0.03, 0.02)
var muescas := [
	Color(0.78, 0.13, 0.13),
	Color(0.13, 0.55, 0.15),
	Color(0.87, 0.80, 0.20),
]

var tamano := Vector2.ZERO
var cuerpo := 13
var fuente: Font = null

const fraccion := 0.048

var minimo := 11


func layout(new_frame_size: Vector2) -> void:
	tamano = new_frame_size
	cuerpo = maxi(minimo, int(tamano.y * fraccion))


func load_font() -> void:
	fuente = ThemeDB.fallback_font
	for path in rutas:
		if path.begins_with("res://"):
			if not ResourceLoader.exists(path):
				continue
			var res := load(path)
			if res is Font:
				fuente = res
				return
			continue
		if not FileAccess.file_exists(path):
			continue
		var file_font := FontFile.new()
		if file_font.load_dynamic_font(path) == OK:
			fuente = file_font
			return


func half() -> Vector2:
	return tamano * 0.5


func advance() -> float:
	return cuerpo * avance


func text_width(line: String) -> float:
	return line.length() * advance()


func draw_backdrop(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(-half(), tamano), fondo, true)


func draw_border(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(-half(), tamano), borde, false, 1.0)


func draw_caption(canvas: CanvasItem, caption: String) -> void:
	var h := half()
	text(canvas, Vector2(-h.x, -h.y - cuerpo * 0.5), caption, titulo)


func draw_status(canvas: CanvasItem, primary: String, secondary: String, hints: String) -> void:
	var h := half()
	var bar_top := h.y + cuerpo * 0.8
	var baseline := bar_top + cuerpo
	var step := advance()

	var x := -h.x
	var segment := step * 0.74
	for i in range(bloques):
		canvas.draw_rect(
			Rect2(
				Vector2(x, bar_top + cuerpo * 0.22),
				Vector2(segment, cuerpo * 0.78)
			),
			muescas[patron[i]],
			true
		)
		x += step

	x += step * 2.0
	x += text(canvas, Vector2(x, baseline), primary, tinta)
	text(canvas, Vector2(x + step * 2.0, baseline), hints, tinta)
	text(canvas, Vector2(-h.x, baseline + cuerpo * 1.6), secondary, tinta)


func draw_debug(canvas: CanvasItem, lines: PackedStringArray) -> void:
	var h := half()
	var ancho := 0.0
	for line in lines:
		ancho = maxf(ancho, text_width(line))
	var box_size := Vector2(ancho + cuerpo, lines.size() * cuerpo * 1.25 + cuerpo)
	var box := Rect2(
		Vector2(h.x - box_size.x - cuerpo * 0.4, -h.y + cuerpo * 0.4), box_size
	)
	canvas.draw_rect(box, Color(0.0, 0.0, 0.0, 0.75), true)
	canvas.draw_rect(box, borde, false, 1.0)

	var y := box.position.y + cuerpo * 0.5 + cuerpo
	for line in lines:
		text(canvas, Vector2(box.position.x + cuerpo * 0.5, y), line, titulo)
		y += cuerpo * 1.25


func text(canvas: CanvasItem, pos: Vector2, line: String, color: Color) -> float:
	var step := advance()
	for i in range(line.length()):
		canvas.draw_char(fuente, pos + Vector2(i * step, 0.0), line[i], cuerpo, color)
	return step * line.length()
