extends RefCounted

# Rigged preview uses one original texture; these are mesh regions, not repainted layers.
const TEXTURE := "res://assets/art/effects/gatcha/zeus/portrait/idle_01.png"
const SIZE := Vector2(768, 1280)
const GRID := Vector2i(24, 40)
const TIP := Vector2(550, 375)
const BONES := [
	{"id": "Root", "pivot": Vector2(384, 1200)},
	{"id": "Head", "pivot": Vector2(348, 465)},
	{"id": "CastArm", "pivot": Vector2(305, 480)},
	{"id": "StaffArm", "pivot": Vector2(448, 500)},
	{"id": "HairLeft", "pivot": Vector2(280, 410)},
	{"id": "HairRight", "pivot": Vector2(410, 440)},
	{"id": "ClothLeft", "pivot": Vector2(315, 690)},
	{"id": "ClothRight", "pivot": Vector2(445, 660)},
]
const PARTS := ["Body", "Head", "CastArm", "StaffArm", "HairLeft", "HairRight", "ClothLeft", "ClothRight"]
const TIMES := [0.0, 0.6, 1.4, 2.05, 2.35, 3.1, 4.0, 5.0]
# Degrees, interpolated continuously. Small range protects the merged illustration.
const ROTATIONS := [
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 2, 5, -3, -1, 2, 0, 0],
	[0, 5, 12, -7, -3, 5, -2, 2],
	[0, -3, -7, 8, 5, -6, 4, -4],
	[0, -1, -3, 3, 3, -4, 3, -3],
	[0, 1, 1, -1, -2, 3, -2, 2],
	[0, 0, 0, 0, 1, -1, 1, -1],
	[0, 0, 0, 0, 0, 0, 0, 0],
]
