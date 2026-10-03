extends Node2D

const inclinacion := 0.0
const ancho := 0.90
const proporcion := 2.75
const tope := 0.72
const altura := 0.84
const suelo := 0.94

const fotogramas := 30
const vuelta := 1.0
const mezcla := 0.45
const rotacion := 4.0

const titulo := "Pine 1a"
const pistas := "N next  A auto  D debug  Q quit"

@export var ritmo := 1.0

var _arbol := PineTree.new()
var _viento := PineWind.new()
var _dibujante := PineRender.new()
var _terminal := PineChrome.new()
var _aleatorio := RandomNumberGenerator.new()

var _reloj := 0.0
var _variante := 0
var _ciclo := false
var _cuenta := 0.0
var depurar := false
var tempo := 0.0

var _ventana := Vector2.ZERO
var _escala := 1.0
var _origen := Vector2.ZERO


func _ready() -> void:
	get_window().title = "Tree?"
	_aleatorio.randomize()
	_viento.duracion = mezcla
	_terminal.load_font()
	_relayout()
	_regrow()
	get_viewport().size_changed.connect(_relayout)


func _regrow() -> void:
	_arbol.grow(_aleatorio, PineVariants.tabla)
	_dibujante.configure(_arbol)


func _relayout() -> void:
	var viewport_size := get_viewport_rect().size
	var width := viewport_size.x * ancho
	var height := minf(width / proporcion, viewport_size.y * tope)
	_ventana = Vector2(width, height).floor()
	_terminal.layout(_ventana)
	_escala = _ventana.y * altura
	_origen = Vector2(0.0, -_ventana.y * 0.5 + _ventana.y * suelo)
	position = viewport_size * 0.5
	rotation_degrees = inclinacion
	queue_redraw()


func _process(delta: float) -> void:
	_reloj += delta * ritmo / vuelta * fotogramas
	_viento.fase = fposmod(_reloj, fotogramas) / fotogramas
	_viento.advance(delta)

	if _ciclo:
		_cuenta += delta
		if _cuenta >= rotacion:
			_pick_variant(_variante + 1)

	tempo = lerpf(tempo, 1.0 / maxf(delta, 0.0001), 0.1)
	queue_redraw()


func _draw() -> void:
	_terminal.draw_backdrop(self)
	_viento.solve(_arbol)
	_dibujante.draw_tree(self, _arbol, _viento, _origen, _escala)
	_terminal.draw_border(self)
	_terminal.draw_caption(self, titulo)
	_terminal.draw_status(self, _status_text(), _speed_text(), pistas)
	if depurar:
		_terminal.draw_debug(self, _debug_lines())


func _status_text() -> String:
	return "%02d/%d %s" % [
		int(_reloj) % fotogramas, fotogramas, PineVariants.nombre_de(_variante)
	]


func _speed_text() -> String:
	var texto := "frozen" if ritmo == 0.0 else "x%.2f" % ritmo
	return "1-9,0 variant  S speed %s" % texto


func _debug_lines() -> PackedStringArray:
	return PackedStringArray([
		"pine debug",
		"variant %d %s" % [_variante, PineVariants.nombre_de(_variante)],
		"blend %.2f from %d" % [_viento.mezcla, _viento.origen],
		"frame %02d/%d" % [int(_reloj) % fotogramas, fotogramas],
		"branches %d" % _arbol.ramas.size(),
		"needles %d" % _arbol.needle_count(),
		"fps %.0f" % tempo,
	])


func _pick_variant(index: int) -> void:
	_variante = posmod(index, PineVariants.cuenta())
	_viento.begin_switch(_variante)
	_cuenta = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	match key.keycode:
		KEY_Q, KEY_ESCAPE:
			get_tree().quit()
		KEY_D:
			depurar = not depurar
		KEY_A:
			_ciclo = not _ciclo
			_cuenta = 0.0
		KEY_S:
			ritmo = 0.25 if ritmo > 0.5 else (1.0 if ritmo > 0.0 else 0.0)
		KEY_N:
			_pick_variant(_variante + 1)
		KEY_0, KEY_KP_0:
			_pick_variant(0)
		KEY_1, KEY_KP_1:
			_pick_variant(1)
		KEY_2, KEY_KP_2:
			_pick_variant(2)
		KEY_3, KEY_KP_3:
			_pick_variant(3)
		KEY_4, KEY_KP_4:
			_pick_variant(4)
		KEY_5, KEY_KP_5:
			_pick_variant(5)
		KEY_6, KEY_KP_6:
			_pick_variant(6)
		KEY_7, KEY_KP_7:
			_pick_variant(7)
		KEY_8, KEY_KP_8:
			_pick_variant(8)
		KEY_9, KEY_KP_9:
			_pick_variant(9)
		_:
			_regrow()


