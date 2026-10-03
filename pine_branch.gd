class_name PineBranch
extends RefCounted

var origen := Vector2.ZERO
var escalon := 0.0
var largo := 1.0
var fase := 0.0
var tramos := PackedVector2Array()

var anclajes := PackedVector2Array()
var desplazamientos := PackedVector2Array()
var tintes := PackedFloat32Array()
var indices := PackedInt32Array()
var fases := PackedInt32Array()


func needle_count() -> int:
	return desplazamientos.size()


func segment_count() -> int:
	return maxi(tramos.size() - 1, 0)
