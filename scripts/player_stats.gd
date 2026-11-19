extends Node
class_name PlayerStats

## Gerencia os atributos vitais do protagonista Luan: Vida (RF013).
## (Sistema de fome removido conforme solicitação).

signal vida_alterada(atual: float, maximo: float)
signal jogador_morreu()

@export var vida_maxima: float = 100.0

var vida_atual: float
var esta_vivo: bool = true

func _ready() -> void:
	vida_atual = vida_maxima
	await get_tree().process_frame
	vida_alterada.emit(vida_atual, vida_maxima)

func receber_dano(quantidade: float) -> void:
	if not esta_vivo or quantidade <= 0:
		return
	
	vida_atual = max(0.0, vida_atual - quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)
	
	if vida_atual <= 0.0:
		morrer()

func curar(quantidade: float) -> void:
	if not esta_vivo or quantidade <= 0:
		return
	vida_atual = min(vida_maxima, vida_atual + quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)

func morrer() -> void:
	esta_vivo = false
	print("[PlayerStats] Luan desmaiou por ferimentos.")
	jogador_morreu.emit()
