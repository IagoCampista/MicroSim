extends TabBar

@onready var inspetor 			= %Inspetor
@onready var visualizador_hex 	= %HexView

# Called when the node enters the scene tree for the first time.
func _ready():
	visualizador_hex.hex_foi_selecionado.connect(inspetor.atualizar_tela)
	#Simulador.inicialização_finalizada.connect(restart_hex_view)
#func restart_hex_view():
	#%HexView.replace_by(load("res://Scenes/HexView.tscn").instantiate())
