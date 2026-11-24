extends Node2D
class_name TerraArada

## Canteiro de terra arada preparado com a Enxada de Madeira (RF002).
## - Pode ser regado com o Regador (Bulling).
## - Pode ser desfeito voltando a ser grama ao bater com a Picareta de Madeira.
## - Permite o plantio de sementes e mudas.

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_clique: Area2D = $AreaClique

var esta_molhada: bool = false
var planta_plantada: String = ""

var tex_seca = preload("res://assets/sprites/cenario/terra_arada.png")
var tex_molhada = preload("res://assets/sprites/cenario/terra_molhada.png")

func _ready() -> void:
	z_index = -5 # Garante que fica no chão, abaixo dos personagens e objetos
	area_clique.input_event.connect(_on_area_input_event)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interagir()

func interagir() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	if global_position.distance_to(player.global_position) > 65.0:
		return
	
	var item_ativo = InventoryManager.obter_item_ativo()
	if item_ativo.is_empty():
		return
	
	var tipo = item_ativo.get("tipo", "")
	var id = item_ativo.get("id", "")
	
	# 1. Picareta desfaz a terra arada (volta a ser grama)
	if tipo == "picareta":
		desfazer_canteiro()
		return
	
	# 2. Regador molha a terra
	if id == "bulling" or tipo == "regador":
		regar()
		return

func regar() -> void:
	esta_molhada = true
	sprite.texture = tex_molhada
	print("[Terra] Canteiro regado e umedecido!")

func desfazer_canteiro() -> void:
	# Efeito de poeira e desmanche
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.12)
	await tween.finished
	queue_free()
	print("[Terra] Canteiro desfeito com a Picareta.")
