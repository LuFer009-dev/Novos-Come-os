extends CharacterBody2D
class_name Player

## Gerencia a movimentação em 8 direções e o uso ativo de ferramentas com o mouse e teclado:
## - Machado: corta árvores e tocos ao clicar neles ou bater na direção deles.
## - Enxada: ara a terra da fazenda no local clicado.
## - Picareta: minera rochas de ferro e desmancha canteiros.
## - Regador (Bulling): rega canteiros e acelera o crescimento de árvores.
## - Espada: desfere golpes.
## - Comida: alimenta e cura o Luan.

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
		sprite_ferramenta.z_index = 10

func _physics_process(delta: float) -> void:
	if esta_usando_ferramenta:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	processar_movimento(delta)

func _input(event: InputEvent) -> void:
	# Não usa ferramentas se a janela de inventário estiver aberta na tela
	if HUD.inventario_aberto:
		return
	
	# Clique com botão esquerdo do mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_tela = get_viewport().get_mouse_position()
		var tela_tamanho = get_viewport_rect().size
		
		# Ignora cliques sobre a barra de ferramentas (na parte inferior central da tela)
		if mouse_tela.y > tela_tamanho.y - 95 and abs(mouse_tela.x - tela_tamanho.x * 0.5) < 220:
			return
		
		usar_ferramenta_no_ponto(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	
	# Barra de Espaço (ação na direção em que está olhando)
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		usar_ferramenta_no_ponto(global_position + direcao_olhar * 32.0)
		get_viewport().set_input_as_handled()

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
		
		if raycast_acao:
			raycast_acao.target_position = direcao_olhar * 32.0
		
		if sprite:
			sprite.play("walk")
			atualizar_orientacao_visual(direcao_movimento.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friccao * delta)
		if sprite:
			sprite.play("idle")
	
	move_and_slide()

func atualizar_orientacao_visual(dir_x: float) -> void:
	if sprite == null:
		return
	if dir_x > 0.05:
		sprite.flip_h = true  # Olha para a direita
	elif dir_x < -0.05:
		sprite.flip_h = false # Olha para a esquerda

func usar_ferramenta_no_ponto(pos_alvo: Vector2) -> void:
	if esta_usando_ferramenta:
		return
	
	var item_ativo = InventoryManager.obter_item_ativo()
	if item_ativo.is_empty():
		return
	
	var tipo = item_ativo.get("tipo", "")
	var id = item_ativo.get("id", "")
	var icone = item_ativo.get("icone", null)
	
	# Vira o Luan em direção ao ponto de clique
	var vetor_clique = pos_alvo - global_position
	if vetor_clique.length() > 6.0:
		direcao_olhar = vetor_clique.normalized()
		atualizar_orientacao_visual(direcao_olhar.x)
	
	# Executa animação visual do balanço
	animar_balanco_ferramenta(icone)
	
	# Se clicou perto (até 110px), usa o ponto do clique; senão, usa a frente do Luan
	var dist = global_position.distance_to(pos_alvo)
	var pos_acao = pos_alvo if dist <= 110.0 else (global_position + direcao_olhar * 32.0)
	
	match tipo:
		"machado":
			acao_machado(pos_acao)
		"picareta":
			acao_picareta(pos_acao)
		"ferramenta":
			if id == "enxada_madeira":
				acao_enxada(pos_acao)
			elif id == "bulling":
				acao_regador(pos_acao)
		"arma":
			print("[Espada] Luan atacou com a Espada de Prata!")
		"comida":
			comer_alimento()

func animar_balanco_ferramenta(icone_textura: Texture2D) -> void:
	if sprite_ferramenta == null or icone_textura == null:
		return
	
	esta_usando_ferramenta = true
	sprite_ferramenta.texture = icone_textura
	sprite_ferramenta.visible = true
	
	# Aponta o pivot para a direção em que o Luan está interagindo
	pivot_ferramenta.rotation = direcao_olhar.angle()
	
	var ang_inicio = -50.0
	var ang_fim = 50.0
	if direcao_olhar.x < -0.05:
		ang_inicio = 50.0
		ang_fim = -50.0
	
	sprite_ferramenta.rotation_degrees = ang_inicio
	
	var tween = create_tween()
	tween.tween_property(sprite_ferramenta, "rotation_degrees", ang_fim, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	sprite_ferramenta.visible = false
	esta_usando_ferramenta = false

# --- 1. AÇÃO DO MACHADO ---
func acao_machado(pos: Vector2) -> void:
	var arvore_mais_proxima: Arvore = null
	var menor_dist = 60.0
	
	for arvore in get_tree().get_nodes_in_group("arvores"):
		if not is_instance_valid(arvore):
			continue
		var dist_clique = arvore.global_position.distance_to(pos)
		var dist_jogador = global_position.distance_to(arvore.global_position)
		if dist_jogador <= 110.0 and dist_clique < menor_dist:
			menor_dist = dist_clique
			arvore_mais_proxima = arvore
	
	if arvore_mais_proxima:
		arvore_mais_proxima.golpear_arvore()
	else:
		print("[Machado] Golpe no ar.")

# --- 2. AÇÃO DA PICARETA ---
func acao_picareta(pos: Vector2) -> void:
	# 1. Procura rochas de minério
	var rocha_mais_proxima: RochaMinerio = null
	var menor_dist = 50.0
	
	for rocha in get_tree().get_nodes_in_group("rochas"):
		if not is_instance_valid(rocha):
			continue
		var dist_clique = rocha.global_position.distance_to(pos)
		var dist_jogador = global_position.distance_to(rocha.global_position)
		if dist_jogador <= 110.0 and dist_clique < menor_dist:
			menor_dist = dist_clique
			rocha_mais_proxima = rocha
	
	if rocha_mais_proxima:
		rocha_mais_proxima.golpear_rocha()
		return
	
	# 2. Se bater em um canteiro de terra arada, desmancha-o
	for terra in get_tree().get_nodes_in_group("terras_aradas"):
		if not is_instance_valid(terra):
			continue
		if terra.global_position.distance_to(pos) < 32.0 and global_position.distance_to(terra.global_position) <= 100.0:
			terra.desfazer_canteiro()
			return
	
	print("[Picareta] Golpe no ar.")

# --- 3. AÇÃO DA ENXADA (ARAR A TERRA) ---
func acao_enxada(pos: Vector2) -> void:
	var tile_pos = Vector2(round(pos.x / 32.0) * 32.0, round(pos.y / 32.0) * 32.0)
	
	# Verifica se já existe um canteiro nesta posição
	for terra in get_tree().get_nodes_in_group("terras_aradas"):
		if is_instance_valid(terra) and terra.global_position.distance_to(tile_pos) < 18.0:
			print("[Enxada] Este solo já está arado.")
			return
	
	# Verifica se não há obstáculo na posição
	for obstaculo in get_tree().get_nodes_in_group("arvores") + get_tree().get_nodes_in_group("rochas"):
		if is_instance_valid(obstaculo) and obstaculo.global_position.distance_to(tile_pos) < 24.0:
			print("[Enxada] Terreno bloqueado.")
			return
	
	var novo_canteiro = cena_terra_arada.instantiate() as TerraArada
	novo_canteiro.global_position = tile_pos
	novo_canteiro.add_to_group("terras_aradas")
	get_parent().add_child(novo_canteiro)
	print("[Enxada] Solo arado com sucesso em: ", tile_pos)

# --- 4. AÇÃO DO REGADOR ---
func acao_regador(pos: Vector2) -> void:
	for terra in get_tree().get_nodes_in_group("terras_aradas"):
		if is_instance_valid(terra) and terra.global_position.distance_to(pos) < 32.0 and global_position.distance_to(terra.global_position) <= 100.0:
			terra.regar()
			return
	
	for arvore in get_tree().get_nodes_in_group("arvores"):
		if is_instance_valid(arvore) and arvore.global_position.distance_to(pos) < 50.0 and global_position.distance_to(arvore.global_position) <= 100.0:
			arvore.regar_arvore()
			return
	
	print("[Regador] Água espirrada no solo.")

# --- 5. COMIDA ---
func comer_alimento() -> void:
	if stats and stats.vida_atual < stats.vida_maxima:
		stats.curar(20.0)
		InventoryManager.slots[InventoryManager.slot_ativo]["quantidade"] -= 1
		if InventoryManager.slots[InventoryManager.slot_ativo]["quantidade"] <= 0:
			InventoryManager.slots[InventoryManager.slot_ativo] = null
		InventoryManager.inventario_atualizado.emit()
		print("[Comida] Luan comeu e recuperou 20 HP!")
