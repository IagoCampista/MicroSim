extends Node

const CODIGO_SUCESSO: int = 0
const CODIGO_FALHA: int = 1
const CODIGO_USO_INVALIDO: int = 2


func _ready() -> void:
	Programa.status_atualizado.connect(_status_atualizado)
	Teste.testes_concluidos.connect(_finalizar_execucao)
	call_deferred("_iniciar")

func _iniciar() -> void:
	Simulador.time_delay = 0.0
	Simulador.atualizacao_visual_ativa = false
	Simulador.log_microoperacoes = false

	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	var configuracao: Dictionary = self._interpretar_argumentos(argumentos)

	if not configuracao.get("ok", false):
		self._imprimir_uso(configuracao.get("erro", "Argumentos inválidos."))
		get_tree().quit(CODIGO_USO_INVALIDO)
		return

	match configuracao["modo"]:
		"teste":
			print("Executando teste headless: ", configuracao["caminho"])
			Teste.realizar_um_teste(configuracao["caminho"])
		"pasta":
			var pasta: String = configuracao["caminho"]
			var arquivos: Array[String] = self._obter_arquivos_de_teste(pasta)
			if arquivos.is_empty():
				push_error("Nenhum arquivo .sta encontrado em \"" + pasta + "\".")
				get_tree().quit(CODIGO_FALHA)
				return
			print("Executando testes headless em: ", pasta)
			Teste.realizar_multiplos_testes(pasta, arquivos)

func _interpretar_argumentos(argumentos: PackedStringArray) -> Dictionary:
	if argumentos.is_empty():
		return {"ok": false, "erro": "Nenhum argumento informado."}

	var comando: String = argumentos[0]

	if comando == "--help" or comando == "-h":
		return {"ok": false, "erro": ""}

	if argumentos.size() != 2:
		return {"ok": false, "erro": "Quantidade de argumentos inválida."}

	var caminho: String = self._normalizar_caminho(argumentos[1])

	match comando:
		"--teste", "-t":
			if not FileAccess.file_exists(caminho):
				return {"ok": false, "erro": "Arquivo de teste não encontrado: " + caminho}
			return {"ok": true, "modo": "teste", "caminho": caminho}
		"--pasta", "-p":
			if DirAccess.open(caminho) == null:
				return {"ok": false, "erro": "Pasta de testes não encontrada: " + caminho}
			return {"ok": true, "modo": "pasta", "caminho": caminho}
		_:
			return {"ok": false, "erro": "Comando não reconhecido: " + comando}

func _normalizar_caminho(caminho: String) -> String:
	if caminho.begins_with("res://") or caminho.begins_with("user://"):
		return caminho

	if caminho.is_absolute_path():
		return ProjectSettings.localize_path(caminho)

	if caminho.begins_with("./"):
		caminho = caminho.trim_prefix("./")

	return "res://" + caminho

func _obter_arquivos_de_teste(pasta: String) -> Array[String]:
	var diretorio := DirAccess.open(pasta)
	if diretorio == null:
		return []

	var arquivos: Array[String] = []
	for arquivo in diretorio.get_files():
		if arquivo.match("*.sta"):
			arquivos.append(arquivo)

	arquivos.sort()
	return arquivos

func _status_atualizado(status: String) -> void:
	if status:
		print("[status] ", status)

func _finalizar_execucao(sucesso: bool, mensagem: String) -> void:
	print("[resultado] ", mensagem)
	get_tree().quit(CODIGO_SUCESSO if sucesso else CODIGO_FALHA)

func _imprimir_uso(erro: String = "") -> void:
	if erro:
		push_error(erro)

	print("Uso do runner headless:")
	print("  godot --headless --path . --scene res://Scenes/HeadlessRunner.tscn -- --teste res://Testes/arquivo.sta")
	print("  godot --headless --path . --scene res://Scenes/HeadlessRunner.tscn -- --pasta res://Testes")
