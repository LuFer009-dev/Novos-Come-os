extends Node

## Gerenciador Central de Inventário (RF012 do GDD: 27 espaços no total).
## Slots 0 a 5: Barra de ferramentas rápida (Hotbar).
## Slots 6 a 26: Mochila expandida.

signal inventario_atualizado()
signal slot_ativo_alterado(novo_indice: int)

const TOTAL_SLOTS: int = 27
const SLOTS_HOTBAR: int = 6

var slots: Array = []
var slot_ativo: int = 0:
	set(valor):
		slot_ativo = clampi(valor, 0, SLOTS_HOTBAR - 1)
		slot_ativo_alterado.emit(slot_ativo)

# Banco de dados com os itens do jogo
var itens_db: Dictionary = {
	"enxada_madeira": {
		"nome": "Enxada de Madeira",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/EnxadaMadeira-0001.png",
		"descricao": "Ferramenta essencial para arar a terra da fazenda.",
		"acumulavel": false
	},
	"machado_madeira": {
		"nome": "Machado de Madeira",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/MachadoMadeirat-0001.png",
		"descricao": "Usado para cortar árvores e obter madeira.",
		"acumulavel": false
	},
	"picareta_madeira": {
		"nome": "Picareta de Madeira",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/PicaretaMadeira-0001.png",
		"descricao": "Usada para minerar pedras e minérios.",
		"acumulavel": false
	},
	"espada_prata": {
		"nome": "Espada de Prata",
		"icone": "res://assets/sprites/itens/Armas/Espadas/EspadaPrataSimples-0001.png",
		"descricao": "Arma branca para combater criaturas corrompidas.",
		"acumulavel": false
	},
	"pao": {
		"nome": "Pão Careca",
		"icone": "res://assets/sprites/itens/Comidas/Pratos/pao-careca-0001.png",
		"descricao": "Pão tradicional, macio e nutritivo.",
		"acumulavel": true
	},
	"bulling": {
		"nome": "Regador (Bulling)",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/bulling-0001.png",
		"descricao": "Usado para regar as plantações da fazenda.",
		"acumulavel": false
	},
	"graveto": {
		"nome": "Graveto",
		"icone": "res://assets/sprites/itens/Itens/graveto-0001.png",
		"descricao": "Pedaço de madeira caído de uma árvore.",
		"acumulavel": true
	},
	"ferro": {
		"nome": "Minério de Ferro",
		"icone": "res://assets/sprites/itens/Material/Minerios/ferro-0001.png",
		"descricao": "Minério bruto que pode ser fundido na fornalha.",
		"acumulavel": true
	},
	"tomate": {
		"nome": "Tomate",
		"icone": "res://assets/sprites/itens/Comidas/Ingredientes/tomate-0001.png",
		"descricao": "Fruto vermelho fresco da horta.",
		"acumulavel": true
	},
	"cenoura": {
		"nome": "Cenoura",
		"icone": "res://assets/sprites/itens/Comidas/Ingredientes/cenoura-000.png",
		"descricao": "Cenoura crocante e doce recém-colhida.",
		"acumulavel": true
	}
}

func _ready() -> void:
	inicializar_inventario()

func inicializar_inventario() -> void:
	slots.clear()
	for i in range(TOTAL_SLOTS):
		slots.append(null)
	
	# Preenche os 6 slots da barra rápida com os equipamentos iniciais
	adicionar_item_no_slot(0, "enxada_madeira", 1)
	adicionar_item_no_slot(1, "machado_madeira", 1)
	adicionar_item_no_slot(2, "picareta_madeira", 1)
	adicionar_item_no_slot(3, "espada_prata", 1)
	adicionar_item_no_slot(4, "pao", 3)
	adicionar_item_no_slot(5, "bulling", 1)
	
	inventario_atualizado.emit()

func adicionar_item(id: String, quantidade: int = 1) -> bool:
	if not itens_db.has(id):
		push_warning("Item não encontrado no banco de dados: " + id)
		return false
	
	var info = itens_db[id]
	
	# 1. Tenta acumular se o item for acumulável
	if info.get("acumulavel", false):
		for i in range(TOTAL_SLOTS):
			if slots[i] != null and slots[i]["id"] == id:
				slots[i]["quantidade"] += quantidade
				inventario_atualizado.emit()
				return true
	
	# 2. Procura o primeiro slot vazio
	for i in range(TOTAL_SLOTS):
		if slots[i] == null:
			slots[i] = {
				"id": id,
				"nome": info["nome"],
				"icone": load(info["icone"]),
				"quantidade": quantidade,
				"descricao": info.get("descricao", "")
			}
			inventario_atualizado.emit()
			return true
	
	print("[Inventário] Inventário cheio! (Limite de 27 slots atingido)")
	return false

func adicionar_item_no_slot(index: int, id: String, quantidade: int = 1) -> void:
	if index < 0 or index >= TOTAL_SLOTS or not itens_db.has(id):
		return
	var info = itens_db[id]
	slots[index] = {
		"id": id,
		"nome": info["nome"],
		"icone": load(info["icone"]),
		"quantidade": quantidade,
		"descricao": info.get("descricao", "")
	}

func trocar_slots(origem: int, destino: int) -> void:
	if origem < 0 or origem >= TOTAL_SLOTS or destino < 0 or destino >= TOTAL_SLOTS:
		return
	if origem == destino:
		return
	
	var item_origem = slots[origem]
	var item_destino = slots[destino]
	
	# Se ambos forem do mesmo tipo acumulável, junta as pilhas
	if item_origem != null and item_destino != null and item_origem["id"] == item_destino["id"]:
		var info = itens_db.get(item_origem["id"], {})
		if info.get("acumulavel", false):
			slots[destino]["quantidade"] += item_origem["quantidade"]
			slots[origem] = null
			inventario_atualizado.emit()
			return
	
	# Troca convencional de posições
	slots[destino] = item_origem
	slots[origem] = item_destino
	inventario_atualizado.emit()

func obter_item_ativo() -> Dictionary:
	if slot_ativo >= 0 and slot_ativo < SLOTS_HOTBAR:
		return slots[slot_ativo] if slots[slot_ativo] != null else {}
	return {}

func trocar_slot_ativo(novo_slot: int) -> void:
	self.slot_ativo = novo_slot
