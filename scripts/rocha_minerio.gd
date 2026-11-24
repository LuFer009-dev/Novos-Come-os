extends StaticBody2D
class_name RochaMinerio

## Rocha de minério minerável com a Picareta de Madeira (RF004).
## Ao ser minerada, estremece, racha e dropa pedaços de Minério de Ferro.

@export var vida_maxima: int = 3
@export var item_dropado_id: String = "ferro"
@export var quantidade_drops: int = 2

@onready var sprite: Sprite2D = $Sprite2D
@onready var colisor: CollisionShape2D = $CollisionShape2D
@onready var area_clique: Area2D = $AreaClique

var vida_atual: int
var cena_item = preload("res://cenas/item_coletavel.tscn")

func _ready() -> void:
	vida_atual = vida_maxima
	area_clique.input_event.connect(_on_area_input_event)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tentar_minerar()

func tentar_minerar() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	var distancia = global_position.distance_to(player.global_position)
	if distancia > 65.0:
		print("[Rocha] Aproxime-se mais para minerar.")
		return
	
	var item_ativo = InventoryManager.obter_item_ativo()
	var tipo = item_ativo.get("tipo", "") if not item_ativo.is_empty() else ""
	
	if tipo == "picareta":
		golpear_rocha()
	else:
		print("[Rocha] Selecione a Picareta de Madeira na barra rápida para minerar!")

func golpear_rocha() -> void:
	vida_atual -= 1
	
	# Efeito visual de tremor de impacto
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", 6.0, 0.03)
	tween.tween_property(sprite, "rotation_degrees", -6.0, 0.03)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.03)
	
	# Flash claro de faísca
	sprite.modulate = Color(1.4, 1.4, 1.4)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	if vida_atual <= 0:
		quebrar_rocha()

func quebrar_rocha() -> void:
	dropar_minerios()
	queue_free()

func dropar_minerios() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(quantidade_drops):
		var item = cena_item.instantiate() as ItemColetavel
		item.item_id = item_dropado_id
		item.quantidade = 1
		
		var angulo = rng.randf_range(0, TAU)
		var raio = rng.randf_range(14, 28)
		var offset = Vector2(cos(angulo) * raio, sin(angulo) * raio)
		item.global_position = global_position + offset
		
		get_parent().add_child(item)
