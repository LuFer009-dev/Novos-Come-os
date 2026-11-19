extends CharacterBody2D
class_name Player

## Gerencia a movimentação em 8 direções do Luan (RF001 do GDD)
## com animações reais de Sprite (Idle / Walk) e física 2D Top-Down.

@export var velocidade: float = 160.0
@export var aceleracao: float = 1200.0
@export var friccao: float = 1000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats: PlayerStats = $PlayerStats

var direcao_olhar: Vector2 = Vector2.DOWN
var direcao_movimento: Vector2 = Vector2.ZERO

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if sprite:
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	processar_movimento(delta)

func processar_movimento(delta: float) -> void:
	var input := Vector2.ZERO
	
	# Suporte a W, A, S, D e Setas do teclado
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input.y += 1.0
	
	# RF001: Normalização diagonal
	direcao_movimento = input.normalized()
	
	if direcao_movimento != Vector2.ZERO:
		direcao_olhar = direcao_movimento
		velocity = velocity.move_toward(direcao_movimento * velocidade, aceleracao * delta)
		
		# Atualiza animação e direção horizontal do Luan
		if sprite:
			sprite.play("walk")
			if direcao_movimento.x > 0.05:
				sprite.flip_h = true  # Olha para a direita
			elif direcao_movimento.x < -0.05:
				sprite.flip_h = false # Olha para a esquerda (original)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friccao * delta)
		if sprite:
			sprite.play("idle")
	
	move_and_slide()
