class_name PineWind
extends RefCounted

var fase := 0.0
var origen := 0
var destino := 0
var mezcla := 1.0
var duracion := 0.45

var torcido := PackedVector2Array()
var anclajes := PackedVector2Array()
var coseno := PackedFloat32Array()
var seno := PackedFloat32Array()
var achatado := PackedFloat32Array()
var previo := 0
var proximo := 0
var amplitud := 0.0
var inclinacion := 0.0

var _tabla := PackedFloat32Array()


func _init() -> void:
	_tabla.resize(PineVariants.tabla)
	for i in range(_tabla.size()):
		_tabla[i] = sin(float(i) / float(_tabla.size()) * TAU)


func sin_at(index: int) -> float:
	return _tabla[index & PineVariants.mascara]


func is_blending() -> bool:
	return origen != destino


func weight() -> float:
	return smoothstep(0.0, 1.0, mezcla)


func begin_switch(index: int) -> bool:
	var next := posmod(index, PineVariants.cuenta())
	if next == destino:
		return false
	origen = destino
	destino = next
	mezcla = 0.0
	return true


func advance(delta: float) -> void:
	if mezcla >= 1.0:
		return
	mezcla = minf(1.0, mezcla + delta / maxf(duracion, 0.0001))
	if mezcla >= 1.0:
		origen = destino


func solve(tree: PineTree) -> void:
	_solve_trunk(tree)
	_solve_branches(tree)
	_solve_flutter()


func _solve_trunk(tree: PineTree) -> void:
	var top := float(maxi(tree.tronco.size() - 1, 1))
	torcido.resize(tree.tronco.size())
	for i in range(tree.tronco.size()):
		var height := float(i) / top
		torcido[i] = tree.tronco[i] + Vector2(_bend(height) * height * height, 0.0)
	inclinacion = _bend(0.0) * 14.0


func _solve_branches(tree: PineTree) -> void:
	var cuenta := tree.ramas.size()
	anclajes.resize(cuenta)
	coseno.resize(cuenta)
	seno.resize(cuenta)
	achatado.resize(cuenta)

	var top := float(maxi(tree.tronco.size() - 1, 1))
	var w := weight()
	for b in range(cuenta):
		var branch := tree.ramas[b]
		var angles := _sway(branch.escalon, branch.largo, w)
		achatado[b] = cos(angles.y)
		coseno[b] = cos(angles.x)
		seno[b] = sin(angles.x)
		var node := clampi(
			int(roundf(branch.origen.y / PineTree.altura * top)), 0, torcido.size() - 1
		)
		anclajes[b] = torcido[node]


func _solve_flutter() -> void:
	var w := weight()
	var amp_from := PineVariants.amplitud(origen, fase)
	var amp_to := PineVariants.amplitud(destino, fase)
	amplitud = lerpf(amp_from, amp_to, w)
	previo = PineVariants.indice(origen, fase)
	proximo = PineVariants.indice(destino, fase)


func _bend(height: float) -> float:
	var to := PineVariants.inclinacion(destino, fase, height)
	if not is_blending():
		return to
	return lerpf(PineVariants.inclinacion(origen, fase, height), to, weight())


func _sway(escalon: float, largo: float, w: float) -> Vector2:
	var to := PineVariants.vaiven(destino, fase, escalon, largo)
	if not is_blending():
		return to
	return PineVariants.vaiven(origen, fase, escalon, largo).lerp(to, w)
