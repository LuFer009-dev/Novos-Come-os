extends TextureRect
class_name SlotUI

## Componente de Slot de Inventário com suporte completo a Drag and Drop (Arrastar e Soltar).

@export var slot_index: int = -1
@export var eh_hotbar: bool = false

var icon_node: TextureRect
var qtd_node: Label
var moldura_node: TextureRect

func _ready() -> void:
	icon_node = get_node_or_null("ItemIcon")
	qtd_node = get_node_or_null("QtdLabel")
	moldura_node = get_node_or_null("Moldura")
	
	# Permite que o mouse interaja e arraste o slot
	mouse_filter = Control.MOUSE_FILTER_STOP
	atualizar()

func configurar(indice: int, is_hotbar: bool = false) -> void:
	slot_index = indice
	eh_hotbar = is_hotbar
	atualizar()

func atualizar() -> void:
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return
	
	if icon_node == null:
		icon_node = get_node_or_null("ItemIcon")
	if qtd_node == null:
		qtd_node = get_node_or_null("QtdLabel")
	
	var item = InventoryManager.slots[slot_index]
	if item != null:
		if icon_node:
			icon_node.texture = item["icone"]
			icon_node.visible = true
		if qtd_node:
			qtd_node.text = str(item["quantidade"]) if item["quantidade"] > 1 else ""
		tooltip_text = "%s\n%s" % [item["nome"], item.get("descricao", "")]
	else:
		if icon_node:
			icon_node.texture = null
			icon_node.visible = false
		if qtd_node:
			qtd_node.text = ""
		tooltip_text = ""

func _gui_input(event: InputEvent) -> void:
	# Se for slot da barra de ferramentas e o jogador clicar com o botão esquerdo, ativa esse slot
	if eh_hotbar and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_index >= 0 and slot_index < InventoryManager.SLOTS_HOTBAR:
			InventoryManager.trocar_slot_ativo(slot_index)

# 1. Início do Arraste (Drag)
func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return null
	
	var item = InventoryManager.slots[slot_index]
	if item == null:
		return null # Nada para arrastar
	
	# Cria a pré-visualização flutuante acompanhando o ponteiro do mouse
	var preview_root = Control.new()
	var preview_icon = TextureRect.new()
	preview_icon.texture = item["icone"]
	preview_icon.custom_minimum_size = Vector2(36, 36)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.position = -Vector2(18, 18) # Centraliza no cursor
	preview_root.add_child(preview_icon)
	
	set_drag_preview(preview_root)
	
	return {
		"origem_index": slot_index
	}

# 2. Verificação se pode soltar (Can Drop)
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("origem_index") and data["origem_index"] != slot_index

# 3. Soltar (Drop)
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("origem_index"):
		var origem = data["origem_index"]
		InventoryManager.trocar_slots(origem, slot_index)
