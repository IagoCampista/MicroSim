extends Node

# na documentação, memória teria 65536 Kib,
# mas na prática a memória possui 4096 Kib
const TAMANHO_MEMORIA 		: int = 0x1000 # 4096
var celulas 				: PackedByteArray
@onready var endereco_selecionado: Valor = Valor.new(0)

signal memoria_foi_recarregada
signal endereço_de_memoria_foi_atualizado
signal grupo_da_memoria_foi_atualizado


# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: no futuro, permitir alterar o tamanho de memória
	celulas.resize(TAMANHO_MEMORIA)

	Estado.sobrecarregar_memoria.connect(sobrescrever_toda_a_memoria)

func atualizar_valor_no_endereco_selecionado(valor: Valor):
	if not self.validar_endereco(self.endereco_selecionado, "escrita"):
		return
	celulas.set(self.endereco_selecionado.como_int(), valor.como_int())

	# TODO: talvez o emit não leve parâmetro e a memória 
	# acesse o `self.endereco_selecionado` por padrão
	self.endereço_de_memoria_foi_atualizado.emit(self.endereco_selecionado)

func sobrescrever_toda_a_memoria(novas_celulas : PackedByteArray):
	if novas_celulas.size() != TAMANHO_MEMORIA:
		push_error("A quantidade de dados a serem escritos na memória (", str(novas_celulas.size()), ") é diferente de ", TAMANHO_MEMORIA , ".")
	self.celulas = novas_celulas
	self.memoria_foi_recarregada.emit()

func sobrescrever_parte_da_memoria(novos_dados: PackedByteArray, endereco_inicial: Valor):
	if endereco_inicial.como_int() + novos_dados.size() > TAMANHO_MEMORIA:
		push_error("Os valores a serem escritos na memória ultrapassam o limite de ", TAMANHO_MEMORIA, " bytes.")
		return

	var dados_finais = PackedByteArray()
	dados_finais.append_array(celulas.slice(0, endereco_inicial.como_int())) # Conteúdo antes dos dados sendo sobrescritos
	dados_finais.append_array(novos_dados) # Dados que estão sobrescrevendo
	dados_finais.append_array(celulas.slice(endereco_inicial.como_int() + novos_dados.size(), self.obter_tamanho_atual_da_memoria())) # Conteúdo após os dados sendo sobrescritos
	self.celulas = dados_finais
	self.grupo_da_memoria_foi_atualizado.emit(endereco_inicial, novos_dados.size())

func sobrescrever_uma_celula(novo_dado: int, endereco: int):
	if not self.validar_endereco(Valor.new(endereco), "escrita"):
		return
	self.celulas.set(endereco, novo_dado)
	self.grupo_da_memoria_foi_atualizado.emit(endereco, 1)

func ler_conteudo_no_endereco_selecionado() -> Valor:
	return self.ler_conteudo_no_endereco(self.endereco_selecionado)

func ler_conteudo_no_endereco(endereco: Valor) -> Valor:
	if not self.validar_endereco(endereco, "leitura"):
		return Valor.new(0)
	var celula = self.celulas[endereco.como_int()]
	var novo_valor = Valor.new(celula)
	return novo_valor

func validar_endereco(endereco: Valor, operacao: String = "acesso") -> bool:
	var endereco_int: int = endereco.como_int()
	if endereco_int >= 0 and endereco_int < self.celulas.size():
		return true

	push_error("Tentativa de " + operacao + " fora da faixa da memória no endereço " + endereco.como_hex(4, true) + ".")
	Simulador.finalizar_execucao(false)
	return false

func carregar_arquivo_de_memoria(caminho: String):
	var arquivo : FileAccess 		= FileAccess.open(caminho, FileAccess.READ)
	var valores : PackedByteArray	= arquivo.get_buffer(arquivo.get_length())
	arquivo.close()
	self.sobrescrever_toda_a_memoria(valores)

func obter_tamanho_atual_da_memoria() -> int:
	return self.celulas.size()
