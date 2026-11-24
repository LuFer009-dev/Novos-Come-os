extends CharacterBody2D
class_name Player

## Gerencia a movimentação em 8 direções e o uso ativo de ferramentas:
## - Machado: corta árvores e tocos.
## - Enxada: ara a terra da fazenda criando canteiros de plantio.
## - Picareta: minera rochas de ferro e desmancha canteiros.
## - Espada: golpeia inimigos.
## - Regador (Bulling): rega canteiros e acelera crescimento de árvores.

@export var velocidade: float = 160.0
@export var aceleracao: float = 1200.0
@export var friccao: float = 1000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: PlayerStats = $PlayerStats
@onready var pivot_ferramenta: Node2D = $PivotFerramenta
@onready var sprite_ferramenta: Sprite2D = $PivotFerramenta/SpriteFerramenta
@onready var raycast_acao: RayCast2D = $RayCastAcao

var direcao_olhar: Vector2 = Vector2.DOWN
var direcao_movimento: Vector2 = Vector2.ZERO
var esta_usando_ferramenta: bool = false

var cena_terra_arada = preload("res://cenas/terra_arada.tscn")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if sprite:
		sprite.play("idle")
	if sprite_ferramenta:
		sprite_ferramenta.visible = false

func _physics_process(delta: float) -> void:
	if esta_usando_ferramenta:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	processar_movimento(delta)

func _unhandled_input(event: InputEvent) -> void:
	if esta_usando_ferramenta:
		return
	
	# Clique com o botão esquerdo do mouse ou Barra de Espaço para usar a ferramenta ativa
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		usar_ferramenta_ativa()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		usar_ferramenta_ativa()

func processar_movimento(delta: float) -> void:
	var input := Vector2.ZERO
	
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input.y += 1.0
	
	direcao_movimento = input.normalized()
	
	if direcao_movimento != Vector2.ZERO:
		direcao_olhar = direcao_movimento
		velocity = velocity.move_toward(direcao_movimento * velocidade, aceleracao * delta)
		
		# Atualiza a direção do Raycast de interação
		if raycast_acao:
			raycast_acao.target_position = direcao_olhar * 32.0
		
		if sprite:
			sprite.play("walk")
			if direcao_movimento.x > 0.05:
				sprite.flip_h = true  # Olha para a direita
			elif direcao_movimento.x < -0.05:
				sprite.flip_h = false # Olha para a esquerda
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friccao * delta)
		if sprite:
			sprite.play("idle")
	
	move_and_slide()

func usar_ferramenta_ativa() -> void:
	var item_ativo = InventoryManager.obter_item_ativo()
	if item_ativo.is_empty():
		return
	
	var tipo = item_ativo.get("tipo", "")
	var id = item_ativo.get("id", "")
	var icone = item_ativo.get("icone", null)
	
	# Inicia animação visual de balanço da ferramenta
	animar_balanco_ferramenta(icone)
	
	# Posição do bloco à frente do jogador
	var pos_frente = global_position + (direcao_olhar * 28.0)
	var tile_pos = Vector2(round(pos_frente.x / 32.0) * 32.0, round(pos_frente.y / 32.0) * 32.0)
	
	match tipo:
		"machado":
			executar_acao_machado()
		"picareta":
			executar_acao_picareta()
		"ferramenta":
			if id == "enxada_madeira":
				arar_solo(tile_pos)
			elif id == "bulling":
				regar_solo_ou_arvore()
		"arma":
			executar_golpe_espada()
		"comida":
			comer_alimento()

func animar_balanco_ferramenta(icone_textura: Texture2D) -> void:
	if sprite_ferramenta == null or icone_textura == null:
		return
	
	esta_usando_ferramenta = true
	sprite_ferramenta.texture = icone_textura
	sprite_ferramenta.visible = true
	
	# Define ângulo do golpe de acordo com o lado para o qual o Luan está virado
	var angulo_base = direcao_olhar.angle()
	pivot_ferramenta.rotation = angulo_base
	
	var angulo_inicio = -45.0
	var angulo_fim = 45.0
	if direcao_olhar.x < -0.05:
		angulo_inicio = 45.0
		angulo_fim = -45.0
	
	sprite_ferramenta.rotation_degrees = angulo_inicio
	
	var tween = create_tween()
	tween.tween_property(sprite_ferramenta, "rotation_degrees", angulo_fim, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	sprite_ferramenta.visible = false
	esta_usando_ferramenta = false

# --- AÇÃO 1: MACHADO ---
func executar_acao_machado() -> void:
	var alvo = detectar_alvo_em_frente()
	if alvo is Arvore:
		alvo.golpear_arvore()
		return
	
	# Busca árvores próximas
	for arvore in get_tree().get_nodes_in_group("arvores"):
		if global_position.distance_to(arvore.global_position) < 55.0:
			arvore.golpear_arvore()
			return

# --- AÇÃO 2: PICARETA ---
func executar_acao_picareta() -> void:
	var alvo = detectar_alvo_em_frente()
	if alvo is RochaMinerio:
		alvo.golpear_rocha()
		return
	elif alvo is TerraArada:
		alvo.desfazer_canteiro()
		return
	
	# Busca rochas próximas
	for rocha in get_tree().get_nodes_in_group("rochas"):
		if global_position.distance_to(rocha.global_position) < 50.0:
			rocha.golpear_rocha()
			return

# --- AÇÃO 3: ENXADA (ARAR A TERRA) ---
func arar_solo(tile_pos: Vector2) -> void:
	# Verifica se já existe um canteiro ou obstáculo na posição
	var espaco_ocupado = false
	for terra in get_tree().get_nodes_in_group("terras_aradas"):
		if terra.global_position.distance_to(tile_pos) < 18.0:
			espaco_ocupado = true
			break
	
	if not espaco_ocupado:
		var novo_canteiro = cena_terra_arada.instantiate() as TerraArada
		novo_canteiro.global_position = tile_pos
		novo_canteiro.add_to_group("terras_aradas")
		get_parent().add_child(novo_canteiro)
		print("[Enxada] Solo arado na posição: ", tile_pos)

# --- AÇÃO 4: REGADOR ---
func regar_solo_ou_arvore() -> void:
	for terra in get_tree().get_nodes_in_group("terras_aradas"):
		if global_position.distance_to(terra.global_position) < 45.0:
			terra.regar()
			return
	
	for arvore in get_tree().get_nodes_in_group("arvores"):
		if global_position.distance_to(arvore.global_position) < 55.0:
			arvore.regar_arvore()
			return

# --- AÇÃO 5: ESPADA ---
func executar_golpe_espada() -> void:
	print("[Espada] Luan desferiu um golpe com a Espada de Prata!")

# --- AÇÃO 6: COMIDA ---
func comer_alimento() -> void:
	if stats and stats.vida_atual < stats.vida_maxima:
		stats.curar(20.0)
		InventoryManager.slots[InventoryManager.slot_ativo]["quantidade"] -= 1
		if InventoryManager.slots[InventoryManager.slot_ativo]["quantidade"] <= 0:
			InventoryManager.slots[InventoryManager.slot_ativo] = null
		InventoryManager.inventario_atualizado.emit()
		print("[Comida] Luan comeu e recuperou 20 HP!")

func detectar_alvo_em_frente() -> Node:
	if raycast_acao and raycast_acao.is_colliding():
		return raycast_acao.get_collider()
	return null
