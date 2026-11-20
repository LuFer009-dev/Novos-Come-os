extends TextureRect
class_name SlotUI

## Componente de Slot com Drag and Drop e suporte a filtros de Armadura (Capacete, Peitoral, Calças, Botas).

@export var slot_index: int = -1
@export var eh_hotbar: bool = false
@export var tipo_filtro: String = "" # Vazio = qualquer item; ou "capacete", "peitoral", "calca", "botas"
@export var icone_silhueta: Texture2D

var icon_node: TextureRect
var qtd_node: Label
var silhueta_node: TextureRect

func _ready() -> void:
	icon_node = get_node_or_null("ItemIcon")
	qtd_node = get_node_or_null("QtdLabel")
	silhueta_node = get_node_or_null("Silhueta")
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	atualizar()

func configurar(indice: int, is_hotbar: bool = false, filtro: String = "", silhueta: Texture2D = null) -> void:
	slot_index = indice
	eh_hotbar = is_hotbar
	tipo_filtro = filtro
	icone_silhueta = silhueta
	atualizar()

func atualizar() -> void:
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return
	
	if icon_node == null:
		icon_node = get_node_or_null("ItemIcon")
	if qtd_node == null:
		qtd_node = get_node_or_null("QtdLabel")
	if silhueta_node == null:
		silhueta_node = get_node_or_null("Silhueta")
	
	var item = InventoryManager.slots[slot_index]
	
	if item != null:
		if icon_node:
			icon_node.texture = item["icone"]
			icon_node.visible = true
		if qtd_node:
			qtd_node.text = str(item["quantidade"]) if item["quantidade"] > 1 else ""
		if silhueta_node:
			silhueta_node.visible = false
		
		var texto_def = ("\n+ %d Defesa" % item["defesa"]) if item.get("defesa", 0) > 0 else ""
		tooltip_text = "%s%s\n%s" % [item["nome"], texto_def, item.get("descricao", "")]
	else:
		if icon_node:
			icon_node.texture = null
			icon_node.visible = false
		if qtd_node:
			qtd_node.text = ""
		if silhueta_node:
			if icone_silhueta:
				silhueta_node.texture = icone_silhueta
			silhueta_node.visible = true
		
		# Tooltip orientativo para slots vazios de equipamento
		if tipo_filtro != "":
			tooltip_text = "Slot de " + tipo_filtro.capitalize() + "\nArraste uma armadura correspondente até aqui."
		else:
			tooltip_text = ""

func _gui_input(event: InputEvent) -> void:
	if eh_hotbar and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_index >= 0 and slot_index < InventoryManager.SLOTS_HOTBAR:
			InventoryManager.trocar_slot_ativo(slot_index)

# 1. Início do Arraste (Drag)
func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return null
	
	var item = InventoryManager.slots[slot_index]
	if item == null:
		return null
	
	var preview_root = Control.new()
	var preview_icon = TextureRect.new()
	preview_icon.texture = item["icone"]
	preview_icon.custom_minimum_size = Vector2(36, 36)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.position = -Vector2(18, 18)
	preview_root.add_child(preview_icon)
	
	set_drag_preview(preview_root)
	
	return {
		"origem_index": slot_index
	}

# 2. Verificação se pode soltar (Can Drop)
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("origem_index") and data["origem_index"] != slot_index):
		return false
	
	var origem_idx = data["origem_index"]
	var item_origem = InventoryManager.slots[origem_idx]
	if item_origem == null:
		return false
	
	# Se este slot exige um tipo específico (ex: capacete), valida
	if tipo_filtro != "":
		if item_origem.get("tipo", "") != tipo_filtro:
			return false
	
	# Se a origem for um slot de armadura, o item que está aqui (se houver) precisa caber lá
	if InventoryManager.eh_slot_equipamento(origem_idx):
		var tipo_esperado_origem = InventoryManager.obter_tipo_esperado_slot(origem_idx)
		var item_aqui = InventoryManager.slots[slot_index]
		if item_aqui != null and item_aqui.get("tipo", "") != tipo_esperado_origem:
			return false
	
	return true

# 3. Soltar (Drop)
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("origem_index"):
		InventoryManager.trocar_slots(data["origem_index"], slot_index)
