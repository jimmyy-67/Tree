class_name PineTree
extends RefCounted

const altura := 1.0
const nudos := 26
const niveles := 19
const follaje := 0.15
const alcance := 0.36
const tendido := 1.30
const erguido := 0.42
const verticilo := 4
const pasos := 9
const caida := 0.055

const apertura := 1.05
const germen := 3
const densidad := Vector2i(7, 13)
const largo := Vector2(0.008, 0.026)
const escalonado := 0.85

const amplitud := 0.34
const matas := 110
const cima := 0.030

var tronco := PackedVector2Array()
var ramas: Array[PineBranch] = []
var deriva := PackedFloat32Array()
var colina := PackedFloat32Array()
var fase := PackedFloat32Array()

var _azar := RandomNumberGenerator.new()


func grow(rng: RandomNumberGenerator, sine_table_size: int) -> void:
	_azar = rng
	_grow_trunk()
	_grow_branches(sine_table_size)
	_grow_ground()


func needle_count() -> int:
	var total := 0
	for branch in ramas:
		total += branch.needle_count()
	return total


func segment_count() -> int:
	var total := 0
	for branch in ramas:
		total += branch.segment_count()
	return total


func trunk_node_at(y: float) -> Vector2:
	var scaled := clampf(y / altura, 0.0, 1.0) * float(tronco.size() - 1)
	return tronco[clampi(int(roundf(scaled)), 0, tronco.size() - 1)]


func _grow_trunk() -> void:
	tronco = PackedVector2Array()
	for i in range(nudos):
		tronco.append(Vector2(0.0, float(i) / (nudos - 1) * altura))


func _grow_branches(sine_table_size: int) -> void:
	ramas.clear()
	for escalon in range(niveles):
		var t := float(escalon) / maxf(niveles - 1, 1)
		var y := follaje + t * (altura - follaje)
		var anchor := trunk_node_at(y)

		var spread := pow(1.0 - t, 1.25)
		var tilt := lerpf(tendido, erguido, t)
		for b in range(verticilo):
			var side := 1.0 if (escalon + b) % 2 == 0 else -1.0
			var stagger := _azar.randf_range(-0.012, 0.012) + (0.02 * b if b > 1 else 0.0)
			var vuelo := alcance * spread * _azar.randf_range(0.84, 1.16)
			if b > 1:
				vuelo *= 0.72 - 0.16 * float(b - 2)
			ramas.append(_make_branch(anchor + Vector2(0.0, stagger), vuelo, tilt, y, side, sine_table_size))

	_grow_crown(sine_table_size)


func _grow_crown(sine_table_size: int) -> void:
	var crown := trunk_node_at(altura)
	for i in range(5):
		var vuelo := _azar.randf_range(0.03, 0.075) * (1.0 - float(i) * 0.16)
		var tilt := _azar.randf_range(0.18, 0.62)
		var side := 1.0 if i % 2 == 0 else -1.0
		ramas.append(_make_branch(crown + Vector2(0.0, -float(i) * 0.02), vuelo, tilt, altura, side, sine_table_size))


func _make_branch(
	origen: Vector2, vuelo: float, tilt: float, escalon: float, side: float, sine_table_size: int
) -> PineBranch:
	var branch := PineBranch.new()
	branch.origen = origen
	branch.escalon = escalon
	branch.largo = vuelo
	branch.fase = _azar.randf() * TAU
	branch.tramos = _branch_polyline(origen, vuelo, tilt)
	_grow_needles(branch, escalon, sine_table_size)
	if side < 0.0:
		_mirror(branch)
	return branch


func _branch_polyline(origen: Vector2, vuelo: float, tilt: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(origen)
	var heading := PI * 0.5 - tilt
	var step := vuelo / float(pasos)
	var position := origen
	for s in range(pasos):
		position += Vector2(cos(heading), sin(heading)) * step
		heading += caida
		points.append(position)
	return points


func _grow_needles(branch: PineBranch, escalon: float, sine_table_size: int) -> void:
	var points := branch.tramos
	for s in range(germen, pasos + 1):
		var node := points[s]
		var along := points[s] - points[s - 1]
		var forward := along.angle()
		var tip_ratio := float(s) / float(pasos)
		var count := densidad.x + int(roundf(tip_ratio * float(densidad.y - densidad.x)))
		for k in range(count):
			var angle := forward + _azar.randf_range(-apertura, apertura)
			var length := _azar.randf_range(largo.x, largo.y) * (0.6 + 0.5 * tip_ratio)
			branch.anclajes.append(node - along * _azar.randf_range(0.0, escalonado))
			branch.desplazamientos.append(Vector2(cos(angle), sin(angle)) * length)
			branch.fases.append(_azar.randi() % sine_table_size)
			branch.tintes.append(
				clampf(0.30 + 0.4 * escalon + 0.4 * tip_ratio + _azar.randf_range(-0.14, 0.14), 0.0, 1.0)
			)


func _mirror(branch: PineBranch) -> void:
	for i in range(branch.tramos.size()):
		branch.tramos[i] = Vector2(-branch.tramos[i].x, branch.tramos[i].y)
	for i in range(branch.anclajes.size()):
		branch.anclajes[i] = Vector2(-branch.anclajes[i].x, branch.anclajes[i].y)
		branch.desplazamientos[i] = Vector2(-branch.desplazamientos[i].x, branch.desplazamientos[i].y)


func _grow_ground() -> void:
	deriva.resize(matas)
	colina.resize(matas)
	fase.resize(matas)
	for i in range(matas):
		var sign_x := 1.0 if _azar.randf() < 0.5 else -1.0
		var spread := pow(_azar.randf(), 0.6) * amplitud * sign_x
		deriva[i] = spread
		colina[i] = _azar.randf_range(0.25, 1.0) * cima * (
			1.0 - absf(spread) / amplitud
		)
		fase[i] = _azar.randf() * TAU
