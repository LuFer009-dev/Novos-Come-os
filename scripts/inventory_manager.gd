extends Node

## Gerenciador Central de Inventário e Equipamentos.
## Slots 0 a 5: Barra de ferramentas rápida (Hotbar).
## Slots 6 a 26: Mochila expandida (totalizando 27 slots de inventário, RF012).
## Slots 27 a 30: Equipamentos de Armadura (Capacete, Peitoral, Calças, Botas).

signal inventario_atualizado()
signal slot_ativo_alterado(novo_indice: int)
signal defesa_alterada(total_defesa: int)

const SLOTS_HOTBAR: int = 6
const SLOTS_INVENTARIO: int = 27 # 0 a 26
const TOTAL_SLOTS: int = 31      # 27 inventário + 4 armaduras

const SLOT_CAPACETE: int = 27
const SLOT_PEITORAL: int = 28
const SLOT_CALCA: int = 29
const SLOT_BOTAS: int = 30

var slots: Array = []
var slot_ativo: int = 0:
	set(valor):
		slot_ativo = clampi(valor, 0, SLOTS_HOTBAR - 1)
		slot_ativo_alterado.emit(slot_ativo)

# Banco de dados de itens
var itens_db: Dictionary = {
	"enxada_madeira": {
		"nome": "Enxada de Madeira",
		"tipo": "ferramenta",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/EnxadaMadeira-0001.png",
		"descricao": "Ferramenta essencial para arar a terra da fazenda.",
		"acumulavel": false
	},
	"machado_madeira": {
		"nome": "Machado de Madeira",
		"tipo": "machado",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/MachadoMadeirat-0001.png",
		"descricao": "Usado para cortar árvores e obter madeira. Clique na árvore para cortar!",
		"acumulavel": false
	},
	"picareta_madeira": {
		"nome": "Picareta de Madeira",
		"tipo": "picareta",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/PicaretaMadeira-0001.png",
		"descricao": "Usada para minerar pedras e minérios.",
		"acumulavel": false
	},
	"espada_prata": {
		"nome": "Espada de Prata",
		"tipo": "arma",
		"icone": "res://assets/sprites/itens/Armas/Espadas/EspadaPrataSimples-0001.png",
		"descricao": "Arma branca para combater criaturas corrompidas.",
		"acumulavel": false
	},
	"pao": {
		"nome": "Pão Careca",
		"tipo": "comida",
		"icone": "res://assets/sprites/itens/Comidas/Pratos/pao-careca-0001.png",
		"descricao": "Pão tradicional, macio e nutritivo.",
		"acumulavel": true
	},
	"bulling": {
		"nome": "Regador (Bulling)",
		"tipo": "ferramenta",
		"icone": "res://assets/sprites/itens/Ferramentas/Aplicaveis/bulling-0001.png",
		"descricao": "Usado para regar as plantações da fazenda.",
		"acumulavel": false
	},
	"graveto": {
		"nome": "Graveto",
		"tipo": "material",
		"icone": "res://assets/sprites/itens/Itens/graveto-0001.png",
		"descricao": "Pedaço de madeira obtido de árvores.",
		"acumulavel": true
	},
	"ferro": {
		"nome": "Minério de Ferro",
		"tipo": "material",
		"icone": "res://assets/sprites/itens/Material/Minerios/ferro-0001.png",
		"descricao": "Minério bruto que pode ser fundido na fornalha.",
		"acumulavel": true
	},
	"tomate": {
		"nome": "Tomate",
		"tipo": "comida",
		"icone": "res://assets/sprites/itens/Comidas/Ingredientes/tomate-0001.png",
		"descricao": "Fruto vermelho fresco da horta.",
		"acumulavel": true
	},
	"cenoura": {
		"nome": "Cenoura",
		"tipo": "comida",
		"icone": "res://assets/sprites/itens/Comidas/Ingredientes/cenoura-000.png",
		"descricao": "Cenoura crocante e doce recém-colhida.",
		"acumulavel": true
	},
	"muda_carvalho": {
		"nome": "Muda de Carvalho",
		"tipo": "semente",
		"icone": "res://assets/sprites/itens/muda_carvalho.png",
		"descricao": "Uma jovem muda de carvalho. Plante na terra para crescer uma nova árvore!",
		"acumulavel": true
	},
	# Peças de Armadura
	"capacete_ferro": {
		"nome": "Capacete de Ferro",
		"tipo": "capacete",
		"defesa": 5,
		"icone": "res://assets/sprites/itens/Armadura/Capacete-Molde-0001.png",
		"descricao": "Capacete de ferro resistente (+5 Defesa).",
		"acumulavel": false
	},
	"peitoral_ferro": {
		"nome": "Peitoral de Ferro",
		"tipo": "peitoral",
		"defesa": 12,
		"icone": "res://assets/sprites/itens/Armadura/Peitoralt-Molde-0001.png",
		"descricao": "Armadura pesada para o peito (+12 Defesa).",
		"acumulavel": false
	},
	"calca_ferro": {
		"nome": "Calças de Ferro",
		"tipo": "calca",
		"defesa": 8,
		"icone": "res://assets/sprites/itens/Armadura/Calca-Molde-0001.png",
		"descricao": "Proteção articulada para as pernas (+8 Defesa).",
		"acumulavel": false
	},
	"botas_ferro": {
		"nome": "Botas de Ferro",
		"tipo": "botas",
		"defesa": 4,
		"icone": "res://assets/sprites/itens/Armadura/Botas-Molde-0001.png",
		"descricao": "Botas reforçadas para os pés (+4 Defesa).",
		"acumulavel": false
	}
}

func _ready() -> void:
	inicializar_inventario()

func inicializar_inventario() -> void:
	slots.clear()
	for i in range(TOTAL_SLOTS):
		slots.append(null)
	
	# 1. Equipamentos iniciais da Hotbar (0 a 5)
	adicionar_item_no_slot(0, "enxada_madeira", 1)
	adicionar_item_no_slot(1, "machado_madeira", 1)
	adicionar_item_no_slot(2, "picareta_madeira", 1)
	adicionar_item_no_slot(3, "espada_prata", 1)
	adicionar_item_no_slot(4, "pao", 3)
	adicionar_item_no_slot(5, "bulling", 1)
	
	# 2. Peças de armadura na mochila para o jogador testar equipar (6 a 9)
	adicionar_item_no_slot(6, "capacete_ferro", 1)
	adicionar_item_no_slot(7, "peitoral_ferro", 1)
	adicionar_item_no_slot(8, "calca_ferro", 1)
	adicionar_item_no_slot(9, "botas_ferro", 1)
	
	inventario_atualizado.emit()
	atualizar_defesa()

func adicionar_item(id: String, quantidade: int = 1) -> bool:
	if not itens_db.has(id):
		return false
	
	var info = itens_db[id]
	
	# Tenta acumular nos 27 slots do inventário
	if info.get("acumulavel", false):
		for i in range(SLOTS_INVENTARIO):
			if slots[i] != null and slots[i]["id"] == id:
				slots[i]["quantidade"] += quantidade
				inventario_atualizado.emit()
				return true
	
	# Procura slot vazio no inventário (0 a 26)
	for i in range(SLOTS_INVENTARIO):
		if slots[i] == null:
			slots[i] = criar_dados_item(id, quantidade)
			inventario_atualizado.emit()
			return true
	
	print("[Inventário] Mochila cheia!")
	return false

func adicionar_item_no_slot(index: int, id: String, quantidade: int = 1) -> void:
	if index < 0 or index >= TOTAL_SLOTS or not itens_db.has(id):
		return
	slots[index] = criar_dados_item(id, quantidade)

func criar_dados_item(id: String, quantidade: int) -> Dictionary:
	var info = itens_db[id]
	return {
		"id": id,
		"nome": info["nome"],
		"tipo": info.get("tipo", "comum"),
		"defesa": info.get("defesa", 0),
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
	
	# Verifica restrição de equipamento no slot de destino
	if eh_slot_equipamento(destino):
		var tipo_permitido = obter_tipo_esperado_slot(destino)
		if item_origem != null and item_origem.get("tipo", "") != tipo_permitido:
			return # Tipo incompatível com o slot de armadura
	
	# Verifica restrição de equipamento se estamos soltando algo no slot de origem
	if eh_slot_equipamento(origem):
		var tipo_permitido = obter_tipo_esperado_slot(origem)
		if item_destino != null and item_destino.get("tipo", "") != tipo_permitido:
			return
	
	# Acúmulo se forem iguais e acumuláveis
	if item_origem != null and item_destino != null and item_origem["id"] == item_destino["id"]:
		var info = itens_db.get(item_origem["id"], {})
		if info.get("acumulavel", false):
			slots[destino]["quantidade"] += item_origem["quantidade"]
			slots[origem] = null
			inventario_atualizado.emit()
			atualizar_defesa()
			return
	
	# Troca convencional
	slots[destino] = item_origem
	slots[origem] = item_destino
	inventario_atualizado.emit()
	atualizar_defesa()

func eh_slot_equipamento(indice: int) -> bool:
	return indice >= SLOT_CAPACETE and indice <= SLOT_BOTAS

func obter_tipo_esperado_slot(indice: int) -> String:
	match indice:
		SLOT_CAPACETE: return "capacete"
		SLOT_PEITORAL: return "peitoral"
		SLOT_CALCA: return "calca"
		SLOT_BOTAS: return "botas"
		_: return ""

func obter_defesa_total() -> int:
	var total: int = 0
	for i in [SLOT_CAPACETE, SLOT_PEITORAL, SLOT_CALCA, SLOT_BOTAS]:
		if slots[i] != null:
			total += slots[i].get("defesa", 0)
	return total

func atualizar_defesa() -> void:
	var def = obter_defesa_total()
	defesa_alterada.emit(def)

func obter_item_ativo() -> Dictionary:
	if slot_ativo >= 0 and slot_ativo < SLOTS_HOTBAR:
		return slots[slot_ativo] if slots[slot_ativo] != null else {}
	return {}

func trocar_slot_ativo(novo_slot: int) -> void:
	self.slot_ativo = novo_slot
