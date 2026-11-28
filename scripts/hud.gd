extends CanvasLayer
class_name HUD

static var inventario_aberto: bool = false

## Gerencia a interface do jogo:
## - Barra de Vida (RF013)
## - Barra de Ferramentas Rápida (6 slots - RF015) com indicador visual do slot ativo (teclas 1 a 6)
## - Janela da Mochila / Inventário com 27 slots (RF012)
## - 4 Slots de Equipamento de Armadura (Capacete, Peitoral, Calças, Botas)
## - Sistema completo de Drag and Drop (Arrastar e Soltar)

@onready var container_coracoes: HBoxContainer = $PainelStatus/VBoxContainer/ContainerVidaCoracoes

var tex_vida_cheia = preload("res://assets/sprites/ui/vida/vida-0001.png")
var tex_vida_metade = preload("res://assets/sprites/ui/vida/vidaMetade-0001.png")
var tex_vida_zerada = preload("res://assets/sprites/ui/vida/vidaZerada-0001.png")

# Barra de Ferramentas
@onready var barra_ferramentas: Control = $BarraFerramentas
@onready var container_hotbar: HBoxContainer = $BarraFerramentas/SlotsContainer
@onready var seletor_ativo: TextureRect = $BarraFerramentas/SeletorAtivo
@onready var label_item_ativo: Label = $BarraFerramentas/LabelItemAtivo
@onready var btn_mochila: TextureButton = $BarraFerramentas/BotaoMochila

# Janela da Mochila
@onready var janela_inventario: Control = $JanelaInventario
@onready var grid_inventario: GridContainer = $JanelaInventario/PainelCentral/GridSlots
@onready var btn_fechar_inventario: Button = $JanelaInventario/PainelCentral/BotaoFechar
@onready var label_defesa: Label = $JanelaInventario/PainelCentral/PainelArmaduras/LabelDefesa
@onready var painel_armaduras: VBoxContainer = $JanelaInventario/PainelCentral/PainelArmaduras
@onready var dica_inventario: Label = $JanelaInventario/PainelCentral/Dica

# Abas do Menu do Inventário
@onready var btn_aba_mochila: Button = $JanelaInventario/PainelCentral/BarraAbas/BotaoAbaMochila
@onready var btn_aba_crafting: Button = $JanelaInventario/PainelCentral/BarraAbas/BotaoAbaCrafting

# Elementos de Crafting (Criação de Itens)
@onready var conteudo_crafting: Control = $JanelaInventario/PainelCentral/ConteudoCrafting
@onready var lista_receitas_vbox: VBoxContainer = $JanelaInventario/PainelCentral/ConteudoCrafting/ScrollReceitas/ListaReceitas
@onready var icone_resultado: TextureRect = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/HBoxTopo/IconeResultado
@onready var nome_resultado: Label = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/HBoxTopo/VBoxTexto/NomeResultado
@onready var descricao_resultado: Label = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/HBoxTopo/VBoxTexto/DescricaoResultado
@onready var lista_ingredientes_vbox: VBoxContainer = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/ScrollIngredientes/ListaIngredientes
@onready var btn_criar_craft: Button = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/HBoxAcoes/BotaoCriar
@onready var label_status_craft: Label = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/HBoxAcoes/LabelStatus
@onready var btn_confirmar: Button = $JanelaInventario/PainelCentral/BotaoConfirmar
@onready var campo_busca: LineEdit = $JanelaInventario/PainelCentral/ConteudoCrafting/PainelDetalhes/VBoxDetalhes/BarraBusca/CampoBusca

var termo_busca: String = ""

# Janela de Notificação de Atualização
@onready var janela_atualizacao: Control = $JanelaAtualizacao
@onready var texto_versao_notif: Label = $JanelaAtualizacao/PainelDialogo/VBox/TextoVersao
@onready var texto_msg_notif: Label = $JanelaAtualizacao/PainelDialogo/VBox/TextoMensagem
@onready var btn_ir_ao_site: Button = $JanelaAtualizacao/PainelDialogo/VBox/HBoxBotoes/BotaoIrAoSite
@onready var btn_fechar_notif: Button = $JanelaAtualizacao/PainelDialogo/VBox/HBoxBotoes/BotaoFecharNotif
@onready var verificador_atualizacao: HTTPRequest = $VerificadorAtualizacao

const VERSAO_ATUAL: String = "1.0.0"
const URL_VERSAO_REMOTO: String = "https://raw.githubusercontent.com/LuFer009-dev/Novos-Come-os/main/versao.json"

var receita_selecionada: Dictionary = {}
var url_site_atualizacao: String = "https://github.com/LuFer009-dev/Novos-Come-os/releases/latest"

# Slots de Armadura
@onready var slot_capacete_node: TextureRect = $JanelaInventario/PainelCentral/PainelArmaduras/ContainerArmaduras/SlotCapacete
@onready var slot_peitoral_node: TextureRect = $JanelaInventario/PainelCentral/PainelArmaduras/ContainerArmaduras/SlotPeitoral
@onready var slot_calca_node: TextureRect = $JanelaInventario/PainelCentral/PainelArmaduras/ContainerArmaduras/SlotCalca
@onready var slot_botas_node: TextureRect = $JanelaInventario/PainelCentral/PainelArmaduras/ContainerArmaduras/SlotBotas

var slots_hotbar_nodes: Array = []
var slots_inventario_nodes: Array = []
var slots_armadura_nodes: Array = []

func _ready() -> void:
	conectar_jogador()
	conectar_inventario()
	inicializar_slots_armadura()
	inicializar_grid_inventario()
	atualizar_todos_os_slots()
	atualizar_seletor(InventoryManager.slot_ativo)
	
	btn_mochila.pressed.connect(toggle_inventario)
	btn_fechar_inventario.pressed.connect(toggle_inventario)
	if btn_confirmar:
		btn_confirmar.pressed.connect(toggle_inventario)
	if campo_busca:
		campo_busca.text_changed.connect(_on_campo_busca_text_changed)
	
	# Conexões das Abas de Mochila e Crafting
	btn_aba_mochila.pressed.connect(mostrar_aba_mochila)
	btn_aba_crafting.pressed.connect(mostrar_aba_crafting)
	btn_criar_craft.pressed.connect(_on_botao_criar_craft_pressionado)
	
	# Conexões da Janela de Atualização Automática
	btn_ir_ao_site.pressed.connect(_on_ir_ao_site_pressionado)
	btn_fechar_notif.pressed.connect(_on_fechar_notificacao_pressionado)
	
	mostrar_aba_mochila()
	iniciar_verificacao_atualizacao()

func conectar_jogador() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("PlayerStats"):
		var stats: PlayerStats = player.get_node("PlayerStats")
		stats.vida_alterada.connect(_on_vida_alterada)
		_on_vida_alterada(stats.vida_atual, stats.vida_maxima)

func conectar_inventario() -> void:
	InventoryManager.inventario_atualizado.connect(_on_inventario_atualizado)
	InventoryManager.slot_ativo_alterado.connect(_on_slot_ativo_alterado)
	InventoryManager.defesa_alterada.connect(_on_defesa_alterada)
	
	slots_hotbar_nodes.clear()
	for i in range(InventoryManager.SLOTS_HOTBAR):
		var slot_node = container_hotbar.get_node_or_null("Slot" + str(i + 1))
		if slot_node:
			if not (slot_node is SlotUI):
				slot_node.set_script(preload("res://scripts/slot_ui.gd"))
			slot_node.configurar(i, true)
			slots_hotbar_nodes.append(slot_node)

func inicializar_slots_armadura() -> void:
	var sil_cap = preload("res://assets/sprites/ui/inventario/Equipamentos/SlotCapacete-0001.png")
	var sil_pei = preload("res://assets/sprites/ui/inventario/Equipamentos/SlotPeitoral-0001.png")
	var sil_cal = preload("res://assets/sprites/ui/inventario/Equipamentos/SlotCalcas-0001.png")
	var sil_bot = preload("res://assets/sprites/ui/inventario/Equipamentos/SlotBotas-0001.png")
	
	slots_armadura_nodes = [
		slot_capacete_node,
		slot_peitoral_node,
		slot_calca_node,
		slot_botas_node
	]
	
	slot_capacete_node.configurar(InventoryManager.SLOT_CAPACETE, false, "capacete", sil_cap)
	slot_peitoral_node.configurar(InventoryManager.SLOT_PEITORAL, false, "peitoral", sil_pei)
	slot_calca_node.configurar(InventoryManager.SLOT_CALCA, false, "calca", sil_cal)
	slot_botas_node.configurar(InventoryManager.SLOT_BOTAS, false, "botas", sil_bot)
	
	_on_defesa_alterada(InventoryManager.obter_defesa_total())

func inicializar_grid_inventario() -> void:
	for child in grid_inventario.get_children():
		child.queue_free()
	slots_inventario_nodes.clear()
	
	var tex_slot = preload("res://assets/sprites/ui/inventario/slot-0002.png")
	var tex_moldura = preload("res://assets/sprites/ui/inventario/MolduraSlot.png")
	var slot_script = preload("res://scripts/slot_ui.gd")
	
	# Cria os 27 slots da mochila (9 colunas x 3 linhas)
	for i in range(InventoryManager.SLOTS_INVENTARIO):
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			toggle_inventario()
			get_viewport().set_input_as_handled()
			return
		
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
			var slot_idx = event.physical_keycode - KEY_1
			InventoryManager.trocar_slot_ativo(slot_idx)
			get_viewport().set_input_as_handled()
			return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var novo = (InventoryManager.slot_ativo - 1 + InventoryManager.SLOTS_HOTBAR) % InventoryManager.SLOTS_HOTBAR
			InventoryManager.trocar_slot_ativo(novo)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var novo = (InventoryManager.slot_ativo + 1) % InventoryManager.SLOTS_HOTBAR
			InventoryManager.trocar_slot_ativo(novo)

func toggle_inventario() -> void:
	janela_inventario.visible = !janela_inventario.visible
	inventario_aberto = janela_inventario.visible
	if janela_inventario.visible:
		atualizar_todos_os_slots()

func _on_vida_alterada(atual: float, maximo: float) -> void:
	if not container_coracoes:
		return
	
	var coracoes = container_coracoes.get_children()
	var qtd_coracoes = coracoes.size()
	var hp_por_coracao = maximo / float(qtd_coracoes)
	
	for i in range(qtd_coracoes):
		var hp_base = i * hp_por_coracao
		var c_node = coracoes[i] as TextureRect
		if atual >= hp_base + hp_por_coracao:
			c_node.texture = tex_vida_cheia
		elif atual >= hp_base + (hp_por_coracao * 0.5):
			c_node.texture = tex_vida_metade
		else:
			c_node.texture = tex_vida_zerada

func _on_defesa_alterada(total_defesa: int) -> void:
	if label_defesa:
		label_defesa.text = "🛡️ Defesa: %d" % total_defesa

func _on_inventario_atualizado() -> void:
	atualizar_todos_os_slots()
	atualizar_seletor(InventoryManager.slot_ativo)
	if conteudo_crafting and conteudo_crafting.visible:
		atualizar_painel_crafting()

func _on_slot_ativo_alterado(novo_indice: int) -> void:
	atualizar_seletor(novo_indice)

func atualizar_todos_os_slots() -> void:
	for slot in slots_hotbar_nodes:
		if slot and slot.has_method("atualizar"):
			slot.atualizar()
	
	for slot in slots_inventario_nodes:
		if slot and slot.has_method("atualizar"):
			slot.atualizar()
	
	for slot in slots_armadura_nodes:
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

# ==============================================================================
# CONTROLE DE ABAS (MOCHILA vs CRAFTING)
# ==============================================================================

func mostrar_aba_mochila() -> void:
	if painel_armaduras:
		painel_armaduras.visible = true
	if grid_inventario:
		grid_inventario.visible = true
	if dica_inventario:
		dica_inventario.visible = true
	if conteudo_crafting:
		conteudo_crafting.visible = false
	
	btn_aba_mochila.modulate = Color(1.0, 1.0, 1.0, 1.0)
	btn_aba_crafting.modulate = Color(0.7, 0.7, 0.7, 1.0)
	atualizar_todos_os_slots()

func mostrar_aba_crafting() -> void:
	if painel_armaduras:
		painel_armaduras.visible = false
	if grid_inventario:
		grid_inventario.visible = false
	if dica_inventario:
		dica_inventario.visible = false
	if conteudo_crafting:
		conteudo_crafting.visible = true
	
	btn_aba_mochila.modulate = Color(0.7, 0.7, 0.7, 1.0)
	btn_aba_crafting.modulate = Color(1.0, 1.0, 1.0, 1.0)
	atualizar_painel_crafting()

# ==============================================================================
# SISTEMA DE INTERFACE DE CRAFTING
# ==============================================================================

func _on_campo_busca_text_changed(novo_texto: String) -> void:
	termo_busca = novo_texto.strip_edges().to_lower()
	atualizar_painel_crafting()

func atualizar_painel_crafting() -> void:
	if not lista_receitas_vbox:
		return
	
	for child in lista_receitas_vbox.get_children():
		child.queue_free()
	
	if receita_selecionada.is_empty() and InventoryManager.receitas_db.size() > 0:
		receita_selecionada = InventoryManager.receitas_db[0]
	
	for rec in InventoryManager.receitas_db:
		if termo_busca != "" and not rec["nome"].to_lower().contains(termo_busca):
			continue
		var pode = InventoryManager.pode_criar_receita(rec)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var info_res = InventoryManager.itens_db.get(rec["resultado"]["id"], {})
		if info_res.has("icone"):
			btn.icon = load(info_res["icone"])
			btn.expand_icon = true
		
		var status_str = " ✅" if pode else " (Falta)"
		btn.text = " %s%s" % [rec["nome"], status_str]
		if pode:
			btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		btn.pressed.connect(func():
			selecionar_receita(rec)
		)
		lista_receitas_vbox.add_child(btn)
	
	exibir_detalhes_receita(receita_selecionada)

func selecionar_receita(rec: Dictionary) -> void:
	receita_selecionada = rec
	if label_status_craft:
		label_status_craft.text = ""
	exibir_detalhes_receita(rec)

func exibir_detalhes_receita(rec: Dictionary) -> void:
	if rec.is_empty() or not nome_resultado:
		return
	
	var id_res = rec["resultado"]["id"]
	var qtd_res = rec["resultado"].get("quantidade", 1)
	var info_res = InventoryManager.itens_db.get(id_res, {})
	
	if info_res.has("icone") and icone_resultado:
		icone_resultado.texture = load(info_res["icone"])
	
	nome_resultado.text = "%s (x%d)" % [rec["nome"], qtd_res]
	descricao_resultado.text = rec.get("descricao", "")
	
	for child in lista_ingredientes_vbox.get_children():
		child.queue_free()
	
	for ing in rec.get("ingredientes", []):
		var id_ing = ing["id"]
		var qtd_necessaria = ing["quantidade"]
		var qtd_atual = InventoryManager.obter_quantidade_item(id_ing)
		var info_ing = InventoryManager.itens_db.get(id_ing, {})
		var nome_ing = info_ing.get("nome", id_ing)
		
		var label_ing = Label.new()
		var tem_suficiente = qtd_atual >= qtd_necessaria
		label_ing.text = "• %s: %d / %d %s" % [nome_ing, qtd_atual, qtd_necessaria, "✅" if tem_suficiente else "❌"]
		label_ing.add_theme_font_size_override("font_size", 11)
		if tem_suficiente:
			label_ing.add_theme_color_override("font_color", Color(0.35, 0.95, 0.35))
		else:
			label_ing.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
		
		lista_ingredientes_vbox.add_child(label_ing)
	
	var pode_fabricar = InventoryManager.pode_criar_receita(rec)
	btn_criar_craft.disabled = not pode_fabricar

func _on_botao_criar_craft_pressionado() -> void:
	if receita_selecionada.is_empty():
		return
	
	if InventoryManager.fabricar_item(receita_selecionada):
		label_status_craft.text = "✅ Criado com sucesso!"
		label_status_craft.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		label_status_craft.text = "❌ Falta material ou espaço!"
		label_status_craft.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	
	atualizar_painel_crafting()

# ==============================================================================
# NOTIFICAÇÃO DE ATUALIZAÇÃO AUTOMÁTICA
# ==============================================================================

func iniciar_verificacao_atualizacao() -> void:
	if verificador_atualizacao:
		verificador_atualizacao.request_completed.connect(_on_requisicao_atualizacao_concluida)
		verificador_atualizacao.request(URL_VERSAO_REMOTO)

func _on_requisicao_atualizacao_concluida(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[Atualizador] Verificação de versão ignorada (sem rede ou servidor indisponível).")
		return
	
	var texto_json = body.get_string_from_utf8()
	var dados = JSON.parse_string(texto_json)
	if dados is Dictionary and dados.has("versao"):
		var versao_remota: String = str(dados["versao"])
		if comparar_versoes(versao_remota, VERSAO_ATUAL) > 0:
			exibir_notificacao_atualizacao(dados)

func comparar_versoes(v1: String, v2: String) -> int:
	var partes1 = v1.replace("v", "").split(".")
	var partes2 = v2.replace("v", "").split(".")
	var max_len = maxi(partes1.size(), partes2.size())
	for i in range(max_len):
		var num1 = int(partes1[i]) if i < partes1.size() else 0
		var num2 = int(partes2[i]) if i < partes2.size() else 0
		if num1 > num2:
			return 1
		elif num1 < num2:
			return -1
	return 0

func exibir_notificacao_atualizacao(dados: Dictionary) -> void:
	var nova_versao = dados.get("versao", "")
	var msg = dados.get("mensagem", "Uma nova versão com melhorias está disponível no site oficial.")
	url_site_atualizacao = dados.get("url_site", "https://github.com/LuFer009-dev/Novos-Come-os/releases/latest")
	
	texto_versao_notif.text = "Versão Atual: v%s  ➔  Nova Versão: v%s" % [VERSAO_ATUAL, nova_versao]
	texto_msg_notif.text = msg
	janela_atualizacao.visible = true

func _on_ir_ao_site_pressionado() -> void:
	OS.shell_open(url_site_atualizacao)
	janela_atualizacao.visible = false

func _on_fechar_notificacao_pressionado() -> void:
	janela_atualizacao.visible = false
