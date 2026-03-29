extends Node

signal microoperacao_executada
signal execucao_finalizada
signal mudanca_de_ciclo
signal programa_iniciado


enum Ciclo 			{ BUSCA, DECODIFICACAO, EXECUCAO }
enum ModoExecucao 	{ UNICA_MICROOPERACAO, UNICA_INSTRUCAO, TUDO }

@export var time_delay 		: float 		= 0.1
var execucao_timer			: Timer
var fase_atual 				: Fase 			= Suspensao.new(Busca.new())
var modo_atual 				: ModoExecucao	= ModoExecucao.TUDO
var instrucao_atual			: Instrucao
var atualizacao_visual_ativa: bool 			= true
var fila_de_microoperacoes	: Array 		= []
var ciclo_atual				: Ciclo

# Called when the node enters the scene tree for the first time.
func _ready():
	execucao_timer = Timer.new()
	execucao_timer.one_shot = true
	add_child(execucao_timer)

	self.prepara_o_estado_inicial.call_deferred()
	self.mudanca_de_ciclo.connect(self.atualizar_ciclo_atual)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if execucao_timer.is_stopped() or Teste.teste_em_execucao():
		self.fase_atual.atualizar()

func executar_proxima_microoperacao_da_fila():
	var _instrucao = self.obter_proxima_microoperacao()
	var instrucao: String

	match typeof(_instrucao):
		TYPE_STRING:
			instrucao = _instrucao
		TYPE_DICTIONARY:
			for condicional in _instrucao:
				if UnidadeDeControle.call(condicional):
					for _microoperacao in _instrucao[condicional]:
						# self.inserir_no_comeco_da_fila(_microoperacao)
						self.adicionar_a_fila(_microoperacao)
			return
		_:
			push_error("Operador de instrução inválido")
	
	if not Teste.em_modo_multiplos_teste():
		print("O simulador vai executar: ", instrucao, " | ", self.fila_de_microoperacoes)

	if CPU.has_method(instrucao):
		CPU.call(instrucao)
	else:
		if instrucao == "---":
			self.mudanca_de_ciclo.emit(Ciclo.BUSCA)
		else:
			if UnidadeDeControle.has_method(instrucao):
				UnidadeDeControle.call(instrucao)
			else:
				Simulador.call(instrucao)

			execucao_timer.start(time_delay)
		microoperacao_executada.emit()

func executar_programa(endereco_inicial: Valor, modo: ModoExecucao = ModoExecucao.TUDO):
	CPU.iniciar_registrador_pc(endereco_inicial)
	self.modo_atual = modo
	self.fase_atual.retomar()
	programa_iniciado.emit()

func salvar_codigo_em_memoria(linhas_codigo: PackedStringArray, endereco_inicial: Valor):
	var parte_memoria: PackedByteArray

	for linha in linhas_codigo:
		var bytes: PackedByteArray = self.montar_linha_em_bytes(linha)
		
		# instrução inválida
		if not bytes:
			return
		
		parte_memoria.append_array(bytes)
	
	Memoria.sobrescrever_parte_da_memoria(parte_memoria, endereco_inicial)

func montar_linha_em_bytes(linha: String) -> PackedByteArray:
	var instrucao: Instrucao = Montador.montar(linha)
		
	# instrução inválida
	if not instrucao:
		return []
	
	return instrucao.instrucao_como_bytes()

func preparar_busca_de_instrucao():
	# Coloca todos os microcódigos necessários para a execução de uma operacao em fila
	# Inicia-se a fase de acesso à instrução;

	# Início da instrução
	self.adicionar_a_fila("---")

	# Transferência do PC (Contador de Programa) para o MAR (Registrador de Endereço de Memória);
	self.adicionar_a_fila("transferir_pc_para_mar")
	
	# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
	self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
	
	# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
	self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")

	# O PC é incrementado em 1;
	self.adicionar_a_fila("incrementar_registrador_pc")

func preparar_decodificacao():
	# O valor de MBR (Registrador de Buffer de Memória) é 
	# transferido ao IR (Registrador de Instrução) via o BUS de Dados;
	self.adicionar_a_fila("---")
	self.adicionar_a_fila("transferir_mbr_para_ir")
	self.adicionar_a_fila("decodificar")

func preparar_enderecamento():
	# Estágio de pesquisa e endereço do operando
	self.adicionar_a_fila("---")
	match self.instrucao_atual.enderecamento:
		Instrucao.Enderecamentos.POS_INDEXADO:
			# Transferência de PC para MAR
			self.adicionar_a_fila("transferir_pc_para_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")

			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")

			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")

			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")

			self.adicionar_a_fila("transferir_mar_para_alu_a")
			self.adicionar_a_fila("transferir_ix_para_alu_b")
			self.adicionar_a_fila("adicao_alu_a_alu_b_16_bits")
			self.adicionar_a_fila("transferir_alu_saida_para_mar")

			# O PC é incrementado em 2
			self.adicionar_a_fila("incrementar_registrador_pc")
			self.adicionar_a_fila("incrementar_registrador_pc")


		Instrucao.Enderecamentos.PRE_INDEXADO:
			# Transferência de PC para MAR
			self.adicionar_a_fila("transferir_pc_para_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")
			
			self.adicionar_a_fila("transferir_mar_para_alu_a")
			self.adicionar_a_fila("transferir_ix_para_alu_b")
			self.adicionar_a_fila("adicao_alu_a_alu_b_16_bits")
			self.adicionar_a_fila("transferir_alu_saida_para_mar")

			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")

			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")

			# O PC é incrementado em 2
			self.adicionar_a_fila("incrementar_registrador_pc")
			self.adicionar_a_fila("incrementar_registrador_pc")
		Instrucao.Enderecamentos.INDIRETO:
			# Transferência de PC para MAR
			self.adicionar_a_fila("transferir_pc_para_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")
			
			# O PC é incrementado em 2
			self.adicionar_a_fila("incrementar_registrador_pc")
			self.adicionar_a_fila("incrementar_registrador_pc")
		Instrucao.Enderecamentos.IMEDIATO:
			# Transferência de PC para MAR
			self.adicionar_a_fila("transferir_pc_para_mar")

			# PC é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_pc")
		Instrucao.Enderecamentos.DIRETO:
			# Transferência de PC para MAR
			self.adicionar_a_fila("transferir_pc_para_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")
			
			# O PC é incrementado em 2
			self.adicionar_a_fila("incrementar_registrador_pc")
			self.adicionar_a_fila("incrementar_registrador_pc")
		Instrucao.Enderecamentos.IMPLICITO:
			pass
		Instrucao.Enderecamentos.INDEXADO:
			# Transferência de PC para MAR
			self.adicionar_a_fila("transferir_pc_para_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao AUX via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_aux")
			
			# O MAR é incrementado em 1
			self.adicionar_a_fila("incrementar_registrador_mar")
			
			# Transferência do MAR para o Endereço de Memória via o BUS de Endereço
			self.adicionar_a_fila("transferir_mar_ao_endereco_de_memoria")
			
			# O valor no Endereço de Memória é transferido ao MBR via o BUS de Dados
			self.adicionar_a_fila("transferir_valor_da_memoria_ao_mbr")
			
			# Une MBR e AUX para formar um endereço 16 bits que é transferido para MAR
			self.adicionar_a_fila("unir_mbr_ao_aux_e_transferir_para_mar")
			
			# Somar o valor de IX ao endereço calculado
			self.adicionar_a_fila("transferir_mar_para_alu_a")
			self.adicionar_a_fila("transferir_ix_para_alu_b")
			self.adicionar_a_fila("adicao_alu_a_alu_b_16_bits")
			self.adicionar_a_fila("transferir_alu_saida_para_mar")
			
			# O PC é incrementado em 2
			self.adicionar_a_fila("incrementar_registrador_pc")
			self.adicionar_a_fila("incrementar_registrador_pc")
		_:
			pass

func preparar_execucao():
	# Estágio de execução
	# Busca a lista de microoperacoes enumeradas no recurso do Operador
	var microoperacoes = Operacoes.obter_microoperacoes(self.instrucao_atual.mnemonico)
	self.adicionar_a_fila("---")

	for microoperacao in microoperacoes:
		# Chama a função declarada em CPU que tem nome equivalente ao especificado no microcodigo do operador
		# Nota: `CPU.call("transferir_a_para_mbr")` é equivalente a `CPU.transferir_a_para_mbr()`
		self.adicionar_a_fila(microoperacao)

func finalizar_execucao(sucesso: bool=true):
	self.limpar_fila_de_microoperacoes() # todo: verificar se a lista não esvaziar sozinha é bug ou não
	execucao_finalizada.emit(sucesso)

func prepara_o_estado_inicial(_emitir_sinal_de_finalização: bool = true):
	Estado.carregar_estado()
	# if emitir_sinal_de_finalização:
	# 	self.inicialização_finalizada.emit()

func validar_fim_de_execucao() -> void:
	# Se a instrução atual for CAL EXIT, finalizar a execução
	if CPU.instrucao_atual_finalizacao():
		self.finalizar_execucao()

func limpar_fila_de_microoperacoes() -> void:
	for fase in self.fila_de_microoperacoes:
		self.fila_de_microoperacoes[fase].clear()

func consultar_microperacao_atual() -> Variant:
	if self.fila_esta_vazia():
		return ""
	return self.fila_de_microoperacoes[0]

func obter_nome_fase() -> String:
	match self.fase_atual:
		Simulador.Ciclo.BUSCA: return "BUSCA"
		Simulador.Ciclo.DECODIFICACAO: return "DECODIFICACAO"
		Simulador.Ciclo.EXECUCAO: return "EXECUCAO"
		_:
			return "SUSPENSAO"

func fila_esta_vazia() -> bool:
	return len(self.fila_de_microoperacoes) <= 0

func adicionar_a_fila(microoperacao: Variant) -> void:
	self.fila_de_microoperacoes.push_back(microoperacao)

# func inserir_no_comeco_da_fila(microoperacao: Variant) -> void:
# 	self.fila_de_microoperacoes.push_front(microoperacao)

func obter_proxima_microoperacao() -> Variant:
	return self.fila_de_microoperacoes.pop_front()

func atualizar_ciclo_atual(ciclo: Ciclo) -> void:
	self.ciclo_atual = ciclo

func obter_ciclo_atual() -> String:
	match self.ciclo_atual:
		Ciclo.BUSCA: return "BUSCA"
		Ciclo.DECODIFICACAO: return "DECODIFICACAO"
		Ciclo.EXECUCAO: return "EXECUCAO"
		_:
			return ""

class Fase:
	var em_inicialização: bool = true
	
	func atualizar() -> void:
		if self.em_inicialização:
			self.entrada()
			self.em_inicialização = false
		else:
			self.ação()
	
	func ação() -> void:
		if Simulador.fila_esta_vazia():
			self.saída()
		else:
			Simulador.executar_proxima_microoperacao_da_fila()

			if Simulador.modo_atual == ModoExecucao.UNICA_MICROOPERACAO:
				self.alterar_fase(Suspensao.new(self))
	
	func entrada() -> void:
		pass
	
	func saída() -> void:
		pass
	
	func retomar() -> void:
		pass
	
	func alterar_fase(novo_fase: Fase) -> void:
		Simulador.fase_atual = novo_fase
	
class Busca extends Fase:
	func entrada() -> void:
		Simulador.mudanca_de_ciclo.emit(Ciclo.BUSCA)
		Simulador.preparar_busca_de_instrucao()
	
	func saída() -> void:
		self.alterar_fase(Decodificacao.new())

class Decodificacao extends Fase:
	func entrada():
		Simulador.mudanca_de_ciclo.emit(Ciclo.DECODIFICACAO)
		Simulador.preparar_decodificacao()
	
	func saída() -> void:
		if not Simulador.instrucao_atual:
			self.alterar_fase(Suspensao.new(Busca.new()))
			return
		self.alterar_fase(Enderecamento.new())

class Enderecamento extends Fase:
	func entrada() -> void:
		if not Simulador.instrucao_atual:
			Simulador.finalizar_execucao(false)
			self.alterar_fase(Suspensao.new(Busca.new()))
			return
		Simulador.mudanca_de_ciclo.emit(Ciclo.EXECUCAO)
		Simulador.preparar_enderecamento()
	
	func saída() -> void:
		# Se a instrução atual for CAL EXIT, finalizar a execução
		if CPU.instrucao_atual_finalizacao():
			Simulador.finalizar_execucao(true)
			self.alterar_fase(Suspensao.new(Busca.new()))
		else:
			self.alterar_fase(Execucao.new())

class Execucao extends Fase:
	func entrada() -> void:
		Simulador.preparar_execucao()
	
	func saída() -> void:
		if Simulador.modo_atual == ModoExecucao.UNICA_INSTRUCAO:
			self.alterar_fase(Suspensao.new(Busca.new()))
		else:
			self.alterar_fase(Busca.new())

class Suspensao extends Fase:
	var _fase_anterior: Fase

	func atualizar() -> void:
		pass

	func _init(fase_anterior: Fase) -> void:
		self._fase_anterior = fase_anterior
	
	func retomar() -> void:
		self.alterar_fase(self._fase_anterior)
