extends StaticBody2D
class_name Arvore

## Gerencia o ciclo completo de vida e crescimento da árvore:
## - 4 Estágios de crescimento: Broto -> Pequena -> Média -> Adulta.
## - Crescimento natural ao longo do tempo ou acelerado com o Regador (Bulling).
## - Corte com o Machado de Madeira, deixando toco e dropando gravetos e mudas.

enum Estagio {
	BROTO = 0,
	PEQUENA = 1,
	MEDIA = 2,
	ADULTA = 3,
	TOCO = 4
}

@export var estagio_atual: Estagio = Estagio.ADULTA
@export var crescimento_automatico: bool = true
@export var tempo_por_estagio: float = 25.0 ## Segundos para avançar de estágio

@onready var sprite: Sprite2D = $Sprite2D
@onready var colisor: CollisionShape2D = $CollisionShape2D
@onready var area_clique: Area2D = $AreaClique

var timer_crescimento: float = 0.0
var vida_corte: int = 4
var regada: bool = false

var cena_item = preload("res://cenas/item_coletavel.tscn")

# Texturas dos estágios
var tex_estagios: Dictionary = {
	Estagio.BROTO: preload("res://assets/sprites/cenario/arvore_estagio_0.png"),
	Estagio.PEQUENA: preload("res://assets/sprites/cenario/arvore_estagio_1.png"),
	Estagio.MEDIA: preload("res://assets/sprites/cenario/arvore_estagio_2.png"),
	Estagio.ADULTA: preload("res://assets/sprites/cenario/arvore_carvalho.png"),
	Estagio.TOCO: preload("res://assets/sprites/cenario/toco_arvore.png")
}

func _ready() -> void:
	if colisor and colisor.shape:
		colisor.shape = colisor.shape.duplicate()
	area_clique.input_event.connect(_on_area_clique_input)
	atualizar_visual_estagio(false)

func _process(delta: float) -> void:
	if not crescimento_automatico or estagio_atual >= Estagio.ADULTA:
		return
	
	# Se a árvore foi regada, cresce 2x mais rápido
	var multiplicador = 2.0 if regada else 1.0
	timer_crescimento += delta * multiplicador
	
	if timer_crescimento >= tempo_por_estagio:
		timer_crescimento = 0.0
		regada = false
		avancar_estagio()

func avancar_estagio() -> void:
	if estagio_atual < Estagio.ADULTA:
		estagio_atual = (estagio_atual + 1) as Estagio
		atualizar_visual_estagio(true)

func atualizar_visual_estagio(com_animacao: bool) -> void:
	sprite.texture = tex_estagios[estagio_atual]
	
	# Ajusta posição do sprite e colisão de acordo com o tamanho do estágio
	match estagio_atual:
		Estagio.BROTO:
			sprite.position = Vector2(0, -6)
			colisor.shape.size = Vector2(8, 4)
			colisor.position = Vector2(0, -2)
			vida_corte = 1
		Estagio.PEQUENA:
			sprite.position = Vector2(0, -16)
			colisor.shape.size = Vector2(10, 6)
			colisor.position = Vector2(0, -2)
			vida_corte = 2
		Estagio.MEDIA:
			sprite.position = Vector2(0, -22)
			colisor.shape.size = Vector2(12, 6)
			colisor.position = Vector2(0, -2)
			vida_corte = 3
		Estagio.ADULTA:
			sprite.position = Vector2(0, -28)
			colisor.shape.size = Vector2(14, 8)
			colisor.position = Vector2(0, -2)
			vida_corte = 4
		Estagio.TOCO:
			sprite.position = Vector2(0, -6)
			colisor.shape.size = Vector2(12, 6)
			colisor.position = Vector2(0, -2)
			vida_corte = 2
	
	if com_animacao:
		# Efeito elástico "pop" de crescimento
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.25, 0.8), 0.1)
		tween.tween_property(sprite, "scale", Vector2(0.9, 1.15), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _on_area_clique_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interagir_com_arvore()

func interagir_com_arvore() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	var distancia = global_position.distance_to(player.global_position)
	if distancia > 75.0:
		print("[Árvore] Aproxime-se mais para interagir.")
		return
	
	var item_ativo = InventoryManager.obter_item_ativo()
	var tipo_item = item_ativo.get("tipo", "") if not item_ativo.is_empty() else ""
	var id_item = item_ativo.get("id", "") if not item_ativo.is_empty() else ""
	
	# 1. Se estiver segurando o Regador (Bulling): rega a árvore para acelerar crescimento
	if id_item == "bulling" or tipo_item == "regador":
		regar_arvore()
		return
	
	# 2. Se for broto e estiver de mãos vazias ou pá/enxada: desenterra a muda
	if estagio_atual == Estagio.BROTO:
		colher_muda()
		return
	
	# 3. Se estiver segurando o Machado: corta a árvore
	if tipo_item == "machado":
		golpear_arvore()
		return
	
	print("[Árvore] Use o Machado para cortar ou o Regador para acelerar o crescimento!")

func regar_arvore() -> void:
	if estagio_atual >= Estagio.ADULTA:
		print("[Árvore] Esta árvore já está completamente crescida!")
		return
	
	regada = true
	timer_crescimento += 5.0 # Bônus imediato de crescimento ao regar
	
	# Efeito visual de água / gota
	var tween = create_tween()
	sprite.modulate = Color(0.6, 0.9, 1.2) # Tom azulado molhado
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.5)
	print("[Árvore] Árvore regada! Crescendo mais rápido.")

func golpear_arvore() -> void:
	vida_corte -= 1
	
	# Efeito visual de tremor ao bater o machado
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", 5.0, 0.04)
	tween.tween_property(sprite, "rotation_degrees", -5.0, 0.04)
	tween.tween_property(sprite, "rotation_degrees", 0.04, 0.04)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.04)
	
	sprite.modulate = Color(1.3, 1.2, 0.9)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	if vida_corte <= 0:
		if estagio_atual == Estagio.TOCO:
			destruir_toco()
		else:
			derrubar_arvore()

func derrubar_arvore() -> void:
	# Queda da árvore
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.8, 0.8), 0.15)
	await tween.finished
	
	dropar_itens_corte()
	
	# Passa para o estágio de toco
	estagio_atual = Estagio.TOCO
	atualizar_visual_estagio(false)

func destruir_toco() -> void:
	dropar_item("graveto", 2)
	queue_free()

func colher_muda() -> void:
	dropar_item("muda_carvalho", 1)
	queue_free()

func dropar_itens_corte() -> void:
	var qtd_gravetos = 1
	match estagio_atual:
		Estagio.PEQUENA: qtd_gravetos = 1
		Estagio.MEDIA: qtd_gravetos = 2
		Estagio.ADULTA:
			qtd_gravetos = 4
			dropar_item("muda_carvalho", 1) # Árvore adulta dropa muda para replantar!
	
	dropar_item("graveto", qtd_gravetos)

func dropar_item(item_id: String, quantidade: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(quantidade):
		var item = cena_item.instantiate() as ItemColetavel
		item.item_id = item_id
		item.quantidade = 1
		
		var angulo = rng.randf_range(0, TAU)
		var raio = rng.randf_range(16, 32)
		var offset = Vector2(cos(angulo) * raio, sin(angulo) * raio)
		item.global_position = global_position + offset
		
		get_parent().add_child(item)
