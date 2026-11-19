extends CanvasLayer
class_name HUD

## Gerencia a interface do jogo:
## - Barra de Vida (RF013)
## - Barra de Ferramentas Rápida (6 slots - RF015) com indicador visual do slot ativo (teclas 1 a 6)
## - Janela da Mochila / Inventário com 27 slots (RF012), aberta por 'E' ou pelo botão da mochila
## - Sistema completo de Drag and Drop (Arrastar e Soltar) entre todos os slots

@onready var barra_vida: ProgressBar = $PainelStatus/VBoxContainer/LinhaVida/BarraVida
@onready var texto_vida: Label = $PainelStatus/VBoxContainer/LinhaVida/TextoVida

# Barra de Ferramentas
@onready var barra_ferramentas: Control = $BarraFerramentas
@onready var container_hotbar: HBoxContainer = $BarraFerramentas/SlotsContainer
@onready var seletor_ativo: TextureRect = $BarraFerramentas/SeletorAtivo
@onready var label_item_ativo: Label = $BarraFerramentas/LabelItemAtivo
@onready var btn_mochila: TextureButton = $BarraFerramentas/BotaoMochila

# Janela da Mochila (27 slots)
@onready var janela_inventario: Control = $JanelaInventario
@onready var grid_inventario: GridContainer = $JanelaInventario/PainelCentral/GridSlots
@onready var btn_fechar_inventario: Button = $JanelaInventario/PainelCentral/BotaoFechar

var slots_hotbar_nodes: Array = []
var slots_inventario_nodes: Array = []

func _ready() -> void:
	conectar_jogador()
	conectar_inventario()
	inicializar_grid_inventario()
	atualizar_todos_os_slots()
	atualizar_seletor(InventoryManager.slot_ativo)
	
	btn_mochila.pressed.connect(toggle_inventario)
	btn_fechar_inventario.pressed.connect(toggle_inventario)

func conectar_jogador() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("PlayerStats"):
		var stats: PlayerStats = player.get_node("PlayerStats")
		stats.vida_alterada.connect(_on_vida_alterada)
		_on_vida_alterada(stats.vida_atual, stats.vida_maxima)

func conectar_inventario() -> void:
	InventoryManager.inventario_atualizado.connect(_on_inventario_atualizado)
	InventoryManager.slot_ativo_alterado.connect(_on_slot_ativo_alterado)
	
	# Mapeia e configura os 6 slots da hotbar como SlotUI
	slots_hotbar_nodes.clear()
	for i in range(InventoryManager.SLOTS_HOTBAR):
		var slot_node = container_hotbar.get_node_or_null("Slot" + str(i + 1))
		if slot_node:
			# Adiciona o script de SlotUI se não estiver configurado
			if not (slot_node is SlotUI):
				slot_node.set_script(preload("res://scripts/slot_ui.gd"))
			slot_node.configurar(i, true)
			slots_hotbar_nodes.append(slot_node)

func inicializar_grid_inventario() -> void:
	for child in grid_inventario.get_children():
		child.queue_free()
	slots_inventario_nodes.clear()
	
	var tex_slot = preload("res://assets/sprites/ui/inventario/slot-0002.png")
	var tex_moldura = preload("res://assets/sprites/ui/inventario/MolduraSlot.png")
	var slot_script = preload("res://scripts/slot_ui.gd")
	
	# Cria os 27 slots do inventário (9 colunas x 3 linhas)
	for i in range(InventoryManager.TOTAL_SLOTS):
		var slot_box = TextureRect.new()
		slot_box.set_script(slot_script)
		slot_box.custom_minimum_size = Vector2(40, 40)
		slot_box.texture = tex_slot
		slot_box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var moldura = TextureRect.new()
		moldura.name = "Moldura"
		moldura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		moldura.texture = tex_moldura
		moldura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_box.add_child(moldura)
		
		var icone = TextureRect.new()
		icone.name = "ItemIcon"
		icone.custom_minimum_size = Vector2(28, 28)
		icone.anchors_preset = Control.PRESET_CENTER
		icone.anchor_left = 0.5
		icone.anchor_top = 0.5
		icone.anchor_right = 0.5
		icone.anchor_bottom = 0.5
		icone.offset_left = -14
		icone.offset_top = -14
		icone.offset_right = 14
		icone.offset_bottom = 14
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_box.add_child(icone)
		
		var qtd_label = Label.new()
		qtd_label.name = "QtdLabel"
		qtd_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
		qtd_label.anchor_left = 1.0
		qtd_label.anchor_top = 1.0
		qtd_label.anchor_right = 1.0
		qtd_label.anchor_bottom = 1.0
		qtd_label.offset_left = -20
		qtd_label.offset_top = -14
		qtd_label.offset_right = -2
		qtd_label.offset_bottom = 0
		qtd_label.add_theme_font_size_override("font_size", 10)
		qtd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qtd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_box.add_child(qtd_label)
		
		if i < InventoryManager.SLOTS_HOTBAR:
			var num_label = Label.new()
			num_label.text = str(i + 1)
			num_label.offset_left = 3
			num_label.offset_top = 1
			num_label.offset_right = 15
			num_label.offset_bottom = 15
			num_label.add_theme_font_size_override("font_size", 9)
			num_label.modulate = Color(1, 0.9, 0.4)
			num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_box.add_child(num_label)
		
		grid_inventario.add_child(slot_box)
		slot_box.configurar(i, false)
		slots_inventario_nodes.append(slot_box)

func _unhandled_input(event: InputEvent) -> void:
	# Abrir / fechar mochila com a tecla 'E'
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			toggle_inventario()
			get_viewport().set_input_as_handled()
			return
		
		# Teclas 1 a 6 para trocar de ferramenta rápida
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
			var slot_idx = event.physical_keycode - KEY_1
			InventoryManager.trocar_slot_ativo(slot_idx)
			get_viewport().set_input_as_handled()
			return
	
	# Scroll do mouse para navegar entre os slots
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var novo = (InventoryManager.slot_ativo - 1 + InventoryManager.SLOTS_HOTBAR) % InventoryManager.SLOTS_HOTBAR
			InventoryManager.trocar_slot_ativo(novo)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var novo = (InventoryManager.slot_ativo + 1) % InventoryManager.SLOTS_HOTBAR
			InventoryManager.trocar_slot_ativo(novo)

func toggle_inventario() -> void:
	janela_inventario.visible = !janela_inventario.visible
	if janela_inventario.visible:
		atualizar_todos_os_slots()

func _on_vida_alterada(atual: float, maximo: float) -> void:
	if barra_vida:
		barra_vida.max_value = maximo
		barra_vida.value = atual
	if texto_vida:
		texto_vida.text = "HP: %d/%d" % [int(atual), int(maximo)]

func _on_inventario_atualizado() -> void:
	atualizar_todos_os_slots()
	atualizar_seletor(InventoryManager.slot_ativo)

func _on_slot_ativo_alterado(novo_indice: int) -> void:
	atualizar_seletor(novo_indice)

func atualizar_todos_os_slots() -> void:
	for slot in slots_hotbar_nodes:
		if slot and slot.has_method("atualizar"):
			slot.atualizar()
	
	for slot in slots_inventario_nodes:
		if slot and slot.has_method("atualizar"):
			slot.atualizar()

func atualizar_seletor(indice: int) -> void:
	if indice >= 0 and indice < slots_hotbar_nodes.size():
		var slot_node = slots_hotbar_nodes[indice]
		seletor_ativo.global_position = slot_node.global_position - Vector2(3, 3)
		seletor_ativo.visible = true
		
		var item = InventoryManager.slots[indice]
		if item != null and label_item_ativo:
			label_item_ativo.text = "[Tecla %d] %s" % [indice + 1, item["nome"]]
		elif label_item_ativo:
			label_item_ativo.text = "[Tecla %d] Vazio" % [indice + 1]
