class_name PineVariants
extends RefCounted

const tabla := 512
const mascara := tabla - 1

const variantes := [
	{
		"nombre": "calm",
		"inclinacion": 0.010, "inclinaciones": 1, "desfase": 0.6,
		"vaiven": 0.035, "vaivenes": 1, "retardo": 1.2,
		"transversal": 0.05, "titileo": 0.06, "titileos": 1,
		"rachas": 0, "hondo": 0.0,
	},
	{
		"nombre": "breeze",
		"inclinacion": 0.035, "inclinaciones": 1, "desfase": 1.1,
		"vaiven": 0.120, "vaivenes": 1, "retardo": 1.6,
		"transversal": 0.150, "titileo": 0.120, "titileos": 2,
		"rachas": 0, "hondo": 0.0,
	},
	{
		"nombre": "gusts",
		"inclinacion": 0.055, "inclinaciones": 1, "desfase": 1.4,
		"vaiven": 0.200, "vaivenes": 1, "retardo": 1.9,
		"transversal": 0.100, "titileo": 0.160, "titileos": 3,
		"rachas": 2, "hondo": 0.55,
	},
	{
		"nombre": "leaves",
		"inclinacion": 0.010, "inclinaciones": 1, "desfase": 0.4,
		"vaiven": 0.035, "vaivenes": 2, "retardo": 1.0,
		"transversal": 0.050, "titileo": 0.400, "titileos": 6,
		"rachas": 0, "hondo": 0.0,
	},
	{
		"nombre": "wave",
		"inclinacion": 0.030, "inclinaciones": 1, "desfase": 3.5,
		"vaiven": 0.140, "vaivenes": 1, "retardo": 4.0,
		"transversal": 0.080, "titileo": 0.100, "titileos": 2,
		"rachas": 0, "hondo": 0.0,
	},
	{
		"nombre": "sway",
		"inclinacion": 0.045, "inclinaciones": 1, "desfase": 1.2,
		"vaiven": 0.220, "vaivenes": 1, "retardo": 1.5,
		"transversal": 0.450, "titileo": 0.080, "titileos": 1,
		"rachas": 0, "hondo": 0.0,
	},
	{
		"nombre": "turbulence",
		"inclinacion": 0.050, "inclinaciones": 3, "desfase": 2.2,
		"vaiven": 0.180, "vaivenes": 3, "retardo": 2.6,
		"transversal": 0.350, "titileo": 0.280, "titileos": 5,
		"rachas": 1, "hondo": 0.30,
	},
	{
		"nombre": "short breeze",
		"inclinacion": 0.030, "inclinaciones": 2, "desfase": 1.0,
		"vaiven": 0.160, "vaivenes": 2, "retardo": 1.4,
		"transversal": 0.200, "titileo": 0.140, "titileos": 4,
		"rachas": 0, "hondo": 0.0,
	},
	{
		"nombre": "breathing",
		"inclinacion": 0.060, "inclinaciones": 1, "desfase": 0.9,
		"vaiven": 0.160, "vaivenes": 1, "retardo": 1.2,
		"transversal": 0.100, "titileo": 0.100, "titileos": 1,
		"rachas": 1, "hondo": 0.50,
	},
	{
		"nombre": "storm",
		"inclinacion": 0.070, "inclinaciones": 2, "desfase": 2.6,
		"vaiven": 0.260, "vaivenes": 3, "retardo": 2.9,
		"transversal": 0.500, "titileo": 0.340, "titileos": 5,
		"rachas": 2, "hondo": 0.40,
	},
]


static func cuenta() -> int:
	return variantes.size()


static func variante(index: int) -> Dictionary:
	return variantes[posmod(index, variantes.size())]


static func nombre_de(index: int) -> String:
	return String(variante(index)["nombre"])


static func racha(index: int, fase: float) -> float:
	var r := variante(index)
	var vueltas := int(r["rachas"])
	if vueltas == 0:
		return 1.0
	var profundidad := float(r["hondo"])
	return 1.0 - profundidad * (0.5 - 0.5 * cos(TAU * float(vueltas) * fase))


static func inclinacion(index: int, fase: float, alto: float) -> float:
	var r := variante(index)
	return float(r["inclinacion"]) * racha(index, fase) * sin(
		TAU * float(r["inclinaciones"]) * fase + float(r["desfase"]) * alto
	)


static func vaiven(index: int, fase: float, escalon: float, alcance: float) -> Vector2:
	var r := variante(index)
	var fuerza := racha(index, fase)
	var golpe := TAU * float(r["vaivenes"]) * fase + float(r["retardo"]) * escalon
	return Vector2(
		float(r["vaiven"]) * alcance * fuerza * sin(golpe),
		float(r["transversal"]) * alcance * fuerza * cos(golpe)
	)


static func amplitud(index: int, fase: float) -> float:
	return float(variante(index)["titileo"]) * racha(index, fase)


static func indice(index: int, fase: float) -> int:
	var r := variante(index)
	return int(fase * float(int(r["titileos"])) * tabla)
