class_name PineRender
extends RefCounted

const pasos := 32

const aguja := 1.0
const rama := 1.4
const minimo := 0.5

const pie := 0.020
const copa := 0.0016
const tono := Vector2(0.55, 1.0)
const sombra := 0.72

var paleta := PackedColorArray()

var _puntas := PackedVector2Array()
var _colores := PackedColorArray()
var _lineas := PackedVector2Array()
var _lineas_tintes := PackedColorArray()
var _losa := PackedVector2Array()
var _losa_tintes := PackedColorArray()
var _centros := PackedVector2Array()
var _normales := PackedVector2Array()
var _suelo_puntas := PackedVector2Array()
var _suelo_tintes := PackedColorArray()


func _init(fosforo: Color = Color(0.16, 1.0, 0.22)) -> void:
	paleta.resize(pasos)
	for i in range(pasos):
		var brightness := pow(float(i) / float(pasos - 1), 0.85)
		paleta[i] = Color(
			fosforo.r * brightness, fosforo.g * brightness, fosforo.b * brightness
		)


func configure(tree: PineTree) -> void:
	var needles := tree.needle_count()
	_puntas.resize(needles * 2)
	_colores.resize(needles)
	_lineas.resize(tree.segment_count() * 2)
	_lineas_tintes.resize(tree.segment_count())
	_suelo_puntas.resize(PineTree.matas * 2)
	_suelo_tintes.resize(PineTree.matas)
	_losa.resize(4)
	_losa_tintes.resize(4)

	for branch in tree.ramas:
		branch.indices.resize(branch.tintes.size())
		for i in range(branch.tintes.size()):
			branch.indices[i] = shade_index(branch.tintes[i])


func shade_index(tint: float) -> int:
	return clampi(int(tint * float(pasos - 1)), 0, pasos - 1)


func shade(tint: float) -> Color:
	return paleta[shade_index(tint)]


func needle_count(tree: PineTree) -> int:
	return tree.needle_count()


func draw_tree(
	canvas: CanvasItem, tree: PineTree, wind: PineWind, origin: Vector2, unit: float
) -> void:
	_build_needles(tree, wind, origin, unit)
	_build_branch_lines(tree, wind, origin, unit)
	_build_ground(tree, wind, origin, unit)

	if _colores.size() > 0:
		canvas.draw_multiline_colors(_puntas, _colores, aguja)
	canvas.draw_multiline_colors(_lineas, _lineas_tintes, rama)
	_draw_trunk(canvas, wind, origin, unit)
	canvas.draw_multiline_colors(_suelo_puntas, _suelo_tintes, aguja)


func _build_needles(tree: PineTree, wind: PineWind, origin: Vector2, unit: float) -> void:
	var blended := wind.is_blending()
	var w := wind.weight()
	var amp := wind.amplitud
	var base_from := wind.previo
	var base_to := wind.proximo

	var write := 0
	var origin_x := origin.x
	var origin_y := origin.y
	for b in range(tree.ramas.size()):
		var branch := tree.ramas[b]
		var origen := wind.anclajes[b]
		var c := wind.coseno[b]
		var s := wind.seno[b]
		var short := wind.achatado[b]
		var base_x := origin_x + origen.x * unit
		var base_y := origin_y - origen.y * unit
		var anchors := branch.anclajes
		var offsets := branch.desplazamientos
		var shades := branch.indices
		var phases := branch.fases

		for i in range(offsets.size()):
			var raw := wind.sin_at(base_to + phases[i])
			if blended:
				raw = lerpf(wind.sin_at(base_from + phases[i]), raw, w)
			var flutter := 1.0 + raw * amp
			var ox := offsets[i].x * flutter
			var oy := offsets[i].y * flutter

			var ax := anchors[i].x - branch.origen.x
			var ay := anchors[i].y - branch.origen.y
			var rx := ax * c - ay * s
			var ry := ax * s + ay * c

			_puntas[write] = Vector2(base_x + rx * short * unit, base_y - ry * short * unit)
			_puntas[write + 1] = Vector2(
				base_x + (rx * short + ox * c - oy * s) * unit,
				base_y - (ry * short + ox * s + oy * c) * unit
			)
			_colores[write >> 1] = paleta[shades[i]]
			write += 2


func _build_branch_lines(tree: PineTree, wind: PineWind, origin: Vector2, unit: float) -> void:
	var write := 0
	for b in range(tree.ramas.size()):
		var branch := tree.ramas[b]
		var span := float(branch.segment_count())
		var previous := _plot(_branch_point(branch, 0, wind, b), origin, unit)
		for i in range(1, branch.tramos.size()):
			var current := _plot(_branch_point(branch, i, wind, b), origin, unit)
			_lineas[write] = previous
			_lineas[write + 1] = current
			_lineas_tintes[write >> 1] = shade(
				lerpf(0.38, 0.92, float(i) / span)
			)
			write += 2
			previous = current


func _branch_point(
	branch: PineBranch, index: int, wind: PineWind, b: int
) -> Vector2:
	var origen := wind.anclajes[b]
	var c := wind.coseno[b]
	var s := wind.seno[b]
	var short := wind.achatado[b]
	var rest := branch.tramos[index] - branch.origen
	return Vector2(
		origen.x + (rest.x * c - rest.y * s) * short,
		origen.y + (rest.x * s + rest.y * c) * short
	)


func _build_ground(tree: PineTree, wind: PineWind, origin: Vector2, unit: float) -> void:
	var lean := wind.inclinacion
	var claro := paleta[11]
	for i in range(PineTree.matas):
		var wobble := sin(TAU * wind.fase + tree.fase[i])
		# Tree units all the way in; _plot does the single scaling by unit.
		var x := tree.deriva[i]
		var h := tree.colina[i] * (1.0 + wobble * 0.22)
		_suelo_puntas[i * 2] = _plot(Vector2(x, 0.0), origin, unit)
		_suelo_puntas[i * 2 + 1] = _plot(
			Vector2(x + lean * 0.05 + h * 0.3, h), origin, unit
		)
		_suelo_tintes[i] = claro


func _draw_trunk(canvas: CanvasItem, wind: PineWind, origin: Vector2, unit: float) -> void:
	_centros.resize(wind.torcido.size())
	for i in range(_centros.size()):
		_centros[i] = _plot(wind.torcido[i], origin, unit)
	_draw_taper(
		canvas,
		_centros,
		pie * unit, copa * unit,
		tono.x, tono.y
	)


func _draw_taper(
	canvas: CanvasItem,
	centre: PackedVector2Array,
	half_root: float,
	half_tip: float,
	tint_root: float,
	tint_tip: float
) -> void:
	var count := centre.size()
	if count < 2:
		return
	var span := float(count - 1)
	_normales.resize(count)
	for i in range(count):
		var before := centre[maxi(i - 1, 0)]
		var after := centre[mini(i + 1, count - 1)]
		var delta := after - before
		var direction := delta.normalized() if delta.length_squared() > 0.0001 else Vector2.UP
		_normales[i] = Vector2(-direction.y, direction.x)

	for i in range(count - 1):
		var ratio := float(i) / span
		var ratio_next := float(i + 1) / span
		var near := centre[i]
		var far := centre[i + 1]
		var near_normal := _normales[i]
		var far_normal := _normales[i + 1]
		var half_near := maxf(lerpf(half_root, half_tip, ratio) * 0.5, minimo)
		var half_far := maxf(lerpf(half_root, half_tip, ratio_next) * 0.5, minimo)

		var tint_near := lerpf(tint_root, tint_tip, ratio)
		var tint_far := lerpf(tint_root, tint_tip, ratio_next)
		_losa[0] = near + near_normal * half_near
		_losa[1] = near - near_normal * half_near
		_losa[2] = far - far_normal * half_far
		_losa[3] = far + far_normal * half_far
		_losa_tintes[0] = shade(tint_near)
		_losa_tintes[1] = shade(tint_near * sombra)
		_losa_tintes[2] = shade(tint_far * sombra)
		_losa_tintes[3] = shade(tint_far)
		canvas.draw_polygon(_losa, _losa_tintes, PackedVector2Array())


func _plot(p: Vector2, origin: Vector2, unit: float) -> Vector2:
	return Vector2(origin.x + p.x * unit, origin.y - p.y * unit)
