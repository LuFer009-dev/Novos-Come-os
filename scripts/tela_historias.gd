extends Control

@onready var btn_voltar: Button = $BtnVoltar
@onready var card_historia: PanelContainer = $Central/BtnHistoria
@onready var label_nome_comeco: Label = $Central/BtnHistoria/Margin/HBox/VBoxTexto/NomeComeco
@onready var label_data_comeco: Label = $Central/BtnHistoria/Margin/HBox/VBoxTexto/DataComeco
@onready var btn_editar_historia: Button = $Central/BtnHistoria/Margin/HBox/BtnEditarHistoria
@onready var btn_nova_historia: Button = $Central/BtnNovaHistoria

@onready var modal_novo_comeco: Panel = $ModalNovoComeco
@onready var line_edit_nome: LineEdit = $ModalNovoComeco/VBox/LineEditNome
@onready var btn_confirmar_criacao: Button = $ModalNovoComeco/VBox/HBoxBotoes/BtnConfirmar
@onready var btn_cancelar_criacao: Button = $ModalNovoComeco/VBox/HBoxBotoes/BtnCancelar

const SAVE_FILE_PATH: String = "user://save_game.json"

var nome_save: String = "Começo #1 - Fazenda Paraíso"
var data_save: String = "14/01/2026"

func _ready() -> void:
	carregar_dados_save()
	
	btn_voltar.pressed.connect(_on_voltar_pressed)
	card_historia.gui_input.connect(_on_card_historia_gui_input)
	btn_editar_historia.pressed.connect(_on_editar_pressed)
	btn_nova_historia.pressed.connect(_on_nova_historia_pressed)
	btn_confirmar_criacao.pressed.connect(_on_confirmar_criacao_pressed)
	btn_cancelar_criacao.pressed.connect(_on_cancelar_criacao_pressed)

func carregar_dados_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if json is Dictionary:
			nome_save = json.get("nome", nome_save)
			data_save = json.get("data", data_save)
	
	label_nome_comeco.text = nome_save
	label_data_comeco.text = "Data de Criação\n" + data_save

func salvar_dados_comeco(novo_nome: String) -> void:
	nome_save = novo_nome if novo_nome.strip_edges() != "" else "Novo Começo"
	var datetime = Time.get_datetime_dict_from_system()
	data_save = "%02d/%02d/%d" % [datetime.day, datetime.month, datetime.year]
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var dados = {
		"nome": nome_save,
		"data": data_save
	}
	file.store_string(JSON.stringify(dados))
	
	label_nome_comeco.text = nome_save
	label_data_comeco.text = "Data de Criação\n" + data_save

func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/tela_inicio.tscn")

func _on_card_historia_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		iniciar_jogo()

func _on_editar_pressed() -> void:
	line_edit_nome.text = nome_save
	modal_novo_comeco.visible = true

func _on_nova_historia_pressed() -> void:
	line_edit_nome.text = "Começo #2 - Nova Aventura"
	modal_novo_comeco.visible = true

func _on_confirmar_criacao_pressed() -> void:
	salvar_dados_comeco(line_edit_nome.text)
	modal_novo_comeco.visible = false
	iniciar_jogo()

func _on_cancelar_criacao_pressed() -> void:
	modal_novo_comeco.visible = false

func iniciar_jogo() -> void:
	get_tree().change_scene_to_file("res://cenas/mundo_fazenda.tscn")
