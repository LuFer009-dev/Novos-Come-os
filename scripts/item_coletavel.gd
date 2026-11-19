extends Area2D
class_name ItemColetavel

## Representa um item dropado/coletável no mapa da fazenda.
## Ao encostar no Luan, o item é adicionado ao inventário/barra de ferramentas.

@export var item_id: String = "graveto"
@export var quantidade: int = 1

@onready var sprite: Sprite2D = $Sprite2D

var tempo: float = 0.0
var y_base: float = 0.0

func _ready() -> void:
	y_base = sprite.position.y
	atualizar_visual()
	body_entered.connect(_on_body_entered)

func atualizar_visual() -> void:
	if InventoryManager and InventoryManager.itens_db.has(item_id):
		var icone_path = InventoryManager.itens_db[item_id]["icone"]
		sprite.texture = load(icone_path)

func _process(delta: float) -> void:
	tempo += delta
	# Efeito de flutuação suave para destacar itens no chão
	sprite.position.y = y_base + sin(tempo * 4.0) * 2.5

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if InventoryManager.adicionar_item(item_id, quantidade):
			print("[Coleta] Pegou: ", item_id, " x", quantidade)
			queue_free()
