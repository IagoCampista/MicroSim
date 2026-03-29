extends Node

signal testes_concluidos

var arquivo_de_teste 		: String
var lista_de_testes			: Array[String] = []
var teste_sem_erros			: bool = true
var todos_testes_sem_erros	: bool = true

var _tempo_inicial: float = 0

enum Estagio		{ COMECO, EM_EXECUCAO, EM_ANALISE, FINALIZADO, PARADO }
enum TipoExecucao 	{ UNICO_TESTE, MULTIPLOS_TESTES }

var tipo_de_execucao	: TipoExecucao
var operacao_atual		: Estagio = Estagio.PARADO


func _ready():
	Simulador.execucao_finalizada.connect(teste_finalizado)
	Programa.programa_carregado.connect(atualizar_programa)

func _physics_process(_delta):
	match self.operacao_atual:
		Estagio.COMECO:
			self._tempo_inicial = Time.get_unix_time_from_system()
			self.operacao_atual = Estagio.EM_EXECUCAO
			self.todos_testes_sem_erros = true

			if self.tipo_de_execucao == TipoExecucao.MULTIPLOS_TESTES:
				Programa.status_atualizado.emit("Testes em execução")
			else:
				Programa.status_atualizado.emit("Teste em execução")
		Estagio.EM_EXECUCAO:
			var teste_atual = lista_de_testes.pop_front()
			print("###### ", teste_atual, " ######")
			self.inicializar_teste(teste_atual)
		Estagio.EM_ANALISE:
			pass
		Estagio.FINALIZADO:
			var tempo_final = Time.get_unix_time_from_system()
			var tempo_total = tempo_final - self._tempo_inicial
			print("Tempo total: ", tempo_total, "ms")
			self.operacao_atual = Estagio.PARADO
			
			var plural: String = ""
			if self.tipo_de_execucao == TipoExecucao.MULTIPLOS_TESTES:
				plural = "s"

			var status: String = "sucesso"
			if not self.todos_testes_sem_erros:
				status = "falha"
			
			var mensagem = "Teste" + plural + " finalizado" + plural + " com " + status

			Programa.status_atualizado.emit(mensagem)
			self.testes_concluidos.emit(self.todos_testes_sem_erros, mensagem)
		Estagio.PARADO:
			pass

func inicializar_teste(arquivo : String) -> void:
	self.arquivo_de_teste 	= arquivo
	self.teste_sem_erros 	= true

	# limpar a fila de instruções (não é necessário aqui, mas é mais uma medida de segurança)
	Simulador.limpar_fila_de_microoperacoes()

	# carregar o estado antes de executar o teste
	Estado.carregar_estado(arquivo)
	
	# inicia a execução do teste
	self.executar_teste()

	self.operacao_atual = Estagio.EM_ANALISE


func executar_teste() -> void:
	Simulador.executar_programa(CPU.registrador_pc)

func teste_finalizado(sucesso:bool = true) -> void:
	# realiza a comparação do estado final com o esperado

	if not self.teste_em_execucao():
		return
	
	# carrega o arquivo de estado
	var config: ConfigFile = Estado.obter_configuração_de_estado(self.arquivo_de_teste)

	if not config:
		return
	
	# validando resultado final nos registradores
	self.validar_valor(config, "registrador.a", CPU.registrador_a)
	self.validar_valor(config, "registrador.b", CPU.registrador_b)
	self.validar_valor(config, "registrador.pc", CPU.registrador_pc)
	self.validar_valor(config, "registrador.pp", CPU.registrador_pp)
	self.validar_valor(config, "registrador.aux", CPU.registrador_aux)
	self.validar_valor(config, "registrador.ir", CPU.registrador_ir)
	self.validar_valor(config, "registrador.ix", CPU.registrador_ix)
	self.validar_valor(config, "registrador.mbr", CPU.registrador_mbr)
	self.validar_valor(config, "registrador.mar", CPU.registrador_mar)
	
		# validando resultado final nas flags
	self.validar_valor(config, "flag.z", CPU.flag_z)
	self.validar_valor(config, "flag.n", CPU.flag_n)
	self.validar_valor(config, "flag.c", CPU.flag_c)
	self.validar_valor(config, "flag.o", CPU.flag_o)

	# validando resultado final na memória
	self.validar_memoria(config)

	if self.teste_sem_erros and sucesso:
		print("Teste concluído com sucesso.")
	else:
		self.todos_testes_sem_erros = false
		print("Teste concluído com falhas.")
	
	if self.lista_de_testes_vazia():
		self.operacao_atual = Estagio.FINALIZADO
	else:
		self.operacao_atual = Estagio.EM_EXECUCAO

func atualizar_programa(instrucoes: PackedStringArray):
	if self.teste_em_execucao():
		Simulador.salvar_codigo_em_memoria(instrucoes, CPU.registrador_pc)

func validar_valor(config: ConfigFile, chave: String, valor_atual: Valor) -> void:
	var _valor_esperado = config.get_value("fim", chave, "")
	
	if not _valor_esperado:
		return
	
	if typeof(_valor_esperado) != TYPE_STRING:
		push_error("\"" + chave + "\" tem um tipo inválido.")
		return

	var valor_esperado: Valor = Valor.novo_de_hex(_valor_esperado)

	if not valor_esperado.igual(valor_atual):
		self.teste_sem_erros = false
		print("Falha: \"" + chave + "\" deveria ser \"" + valor_esperado.como_hex(1, true) + "\" mas resultou em \"" + valor_atual.como_hex(1, true) + "\".")

func validar_memoria(config: ConfigFile) -> void:
	var valores_memoria = config.get_value("fim", "memoria", {})

	if typeof(valores_memoria) != TYPE_DICTIONARY:
		push_error("\"memoria\" tem um tipo inválido. Abortando verificação.")
		return

	for _endereco in valores_memoria:
		if typeof(_endereco) != TYPE_STRING:
			push_error("\"memoria\" tem um valor inválido. Abortando verificação.")
			return

		var valor_esperado = valores_memoria[_endereco]

		if typeof(valor_esperado) != TYPE_STRING:
			push_error("\"memoria\" tem um valor inválido. Abortando verificação.")
			return

		var endereco		: Valor = Valor.novo_de_hex(_endereco)
		var _valor_esperado	: Valor = Valor.novo_de_hex(valor_esperado)
		var valor_atual		: int 	= Memoria.celulas[endereco.como_int()]
		var _valor_atual	: Valor = Valor.new(valor_atual)
		
		if not _valor_esperado.igual(_valor_atual):
			self.teste_sem_erros = false
			print("Falha: O valor na memória no endereço \"" + endereco.como_hex(4,true) + "\" deveria ser \"" + _valor_esperado.como_hex(1,true) + "\" mas resultou em \"" + _valor_atual.como_hex(1,true) + "\".")

func adicionar_teste_a_fila(nome : String) -> void:
	self.lista_de_testes.append(nome)

func realizar_multiplos_testes(pasta: String, arquivos: Array[String]) -> void:
	for arquivo in arquivos:
		self.adicionar_teste_a_fila(pasta.path_join(arquivo))
	self.tipo_de_execucao 	= TipoExecucao.MULTIPLOS_TESTES
	self.operacao_atual 	= Estagio.COMECO

func abortar_todos_os_testes() -> void:
	self.lista_de_testes.clear()
	self.operacao_atual		= Estagio.PARADO

func realizar_um_teste(caminho : String) -> void:
	self.adicionar_teste_a_fila(caminho)
	self.tipo_de_execucao 	= TipoExecucao.UNICO_TESTE
	self.operacao_atual		= Estagio.COMECO

func teste_em_execucao() -> bool:
	return (self.operacao_atual != Estagio.PARADO) and (self.operacao_atual != Estagio.FINALIZADO)

func em_modo_multiplos_teste() -> bool:
	return (self.tipo_de_execucao == TipoExecucao.MULTIPLOS_TESTES)

func lista_de_testes_vazia() -> bool:
	return (self.lista_de_testes.size() == 0)
