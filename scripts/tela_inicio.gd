extends Control

@onready var btn_continuar: Button = $PainelEsquerdo/VBoxCentral/Botoes/BtnContinuar
@onready var btn_conquistas: Button = $PainelEsquerdo/VBoxCentral/Botoes/BtnConquistas
@onready var btn_configuracoes: Button = $PainelEsquerdo/VBoxCentral/Botoes/BtnConfiguracoes
@onready var btn_sair: Button = $PainelEsquerdo/VBoxCentral/Botoes/BtnSair

@onready var modal_conquistas: Panel = $ModalConquistas
@onready var modal_config: Panel = $ModalConfiguracoes
@onready var anim_luan: AnimatedSprite2D = $PainelDireito/LuanAnim

func _ready() -> void:
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_conquistas.pressed.connect(_on_conquistas_pressed)
	btn_configuracoes.pressed.connect(_on_configuracoes_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	
	if anim_luan:
		anim_luan.play("idle")

func _on_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/tela_historias.tscn")

func _on_conquistas_pressed() -> void:
	if modal_conquistas:
		modal_conquistas.visible = !modal_conquistas.visible

func _on_configuracoes_pressed() -> void:
	if modal_config:
		modal_config.visible = !modal_config.visible

func _on_sair_pressed() -> void:
	get_tree().quit()

func _on_fechar_modal_conquistas_pressed() -> void:
	if modal_conquistas:
		modal_conquistas.visible = false

func _on_fechar_modal_config_pressed() -> void:
	if modal_config:
		modal_config.visible = false
