extends TabBar

var registradores_interagindo 	: Array[Button] = []
var tweens_piscar_registradores	: Array[Tween]

var fluxo_tween					: Tween
@export var tempo_fluxo			: float = 1

var fluxo_ligado : Node2D

var tween_memoria: Tween
var WAIT_TIME = 0.5

var flags_atualizadas: Array[Button] = []

@onready var registradores_nos = {
	"A": %RegistradorAButton,
	"B": %RegistradorBButton,
	"PC": %RegistradorPCButton,
	"IX": %RegistradorIXButton,
	"MAR": %RegistradorMARButton,
	"PP": %RegistradorPPButton,
	"MBR": %RegistradorMBRButton,
	"AUX": %RegistradorAUXButton,
	"Z": %RegistradorZButton,
	"N": %RegistradorNButton,
	"C": %RegistradorCButton,
	"O": %RegistradorOButton,
	"IR": %RegistradorIRButton,
	"MemoriaEndereco": %MemoriaEnderecoButton,
	"MemoriaValor": %MemoriaValorButton,
	"ULAA": %RegistradorULAAButton,
	"ULAB": %RegistradorULABButton,
	"ULASaida": %RegistradorULASaidaButton
}

# Called when the node enters the scene tree for the first time.
func _ready():
	Simulador.microoperacao_executada.connect(atualizar_visualizacao)
	
	CPU.registrador_a_foi_atualizado.connect(atualizar_registrador.bind("A"))
	CPU.registrador_b_foi_atualizado.connect(atualizar_registrador.bind("B"))
	CPU.registrador_pc_foi_atualizado.connect(atualizar_registrador.bind("PC"))
	CPU.registrador_ix_foi_atualizado.connect(atualizar_registrador.bind("IX"))
	CPU.registrador_pp_foi_atualizado.connect(atualizar_registrador.bind("PP"))
	CPU.registrador_mbr_foi_atualizado.connect(atualizar_registrador.bind("MBR"))
	CPU.registrador_aux_foi_atualizado.connect(atualizar_registrador.bind("AUX"))
	CPU.registrador_mar_foi_atualizado.connect(atualizar_registrador.bind("MAR"))
	CPU.flag_z_foi_atualizada.connect(atualizar_registrador.bind("Z"))
	CPU.flag_n_foi_atualizada.connect(atualizar_registrador.bind("N"))
	CPU.flag_c_foi_atualizada.connect(atualizar_registrador.bind("C"))
	CPU.flag_o_foi_atualizada.connect(atualizar_registrador.bind("O"))
	CPU.registrador_ir_foi_atualizado.connect(atualizar_registrador.bind("IR"))

	Simulador.programa_iniciado.connect(limpar_flags)
	CPU.flag_z_foi_atualizada.connect(adicionar_flags_interagindo.bind(%RegistradorZButton))
	CPU.flag_n_foi_atualizada.connect(adicionar_flags_interagindo.bind(%RegistradorNButton))
	CPU.flag_c_foi_atualizada.connect(adicionar_flags_interagindo.bind(%RegistradorCButton))
	CPU.flag_o_foi_atualizada.connect(adicionar_flags_interagindo.bind(%RegistradorOButton))

	CPU.alu_entrada_a_foi_atualizado.connect(atualizar_registrador.bind("ULAA"))
	CPU.alu_entrada_b_foi_atualizado.connect(atualizar_registrador.bind("ULAB"))
	CPU.alu_saida_foi_atualizado.connect(atualizar_registrador.bind("ULASaida"))

	Simulador.mudanca_de_ciclo.connect(fase_foi_alterada)
func atualizar_visualizacao():
	# Resolvendo caixas
	apagar_tweens()

	if not Simulador.atualizacao_visual_ativa:
		return
	
	if Simulador.fila_esta_vazia():
		return
	
	var microoperacao_atual = Simulador.consultar_microperacao_atual()
	# print("A próxima instrução do visual será: ", microoperacao_atual)
	
	if not microoperacao_atual or typeof(microoperacao_atual) != TYPE_STRING:
		return

	if Simulador.instrucao_atual and not Simulador.instrucao_atual.parametro:
		Simulador.instrucao_atual.parametro = Simulador.instrucao_atual.capturar_parametro_no_prox_endereço() if Simulador.instrucao_atual else ""
	
	var nome_instrucao = Simulador.instrucao_atual.instrucao_em_string() if Simulador.instrucao_atual else "???"
	%InstrucaoAtualLabel.text = "Microoperação atual: " + str(microoperacao_atual) + " | Instrução: " + nome_instrucao
	
	remover_fluxos()
	match microoperacao_atual:
		"transferir_pc_para_mar":
			adicionar_fila_registrador_interagindo(["PC", "MAR"])
		"transferir_mbr_para_ir":
			adicionar_fila_registrador_interagindo(["MBR", "IR"])
		"transferir_mbr_para_a", "transferir_a_para_mbr":
			adicionar_fila_registrador_interagindo(["MBR", "A"])
		"transferir_mbr_para_b", "transferir_b_para_mbr":
			adicionar_fila_registrador_interagindo(["MBR", "B"])
		"transferir_aux_para_b":
			adicionar_fila_registrador_interagindo(["AUX", "B"])
		"unir_mbr_ao_aux_e_transferir_para_mar":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "MAR"])
		"unir_mbr_ao_aux_e_transferir_para_pc":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "PC"])
		"unir_mbr_ao_aux_e_transferir_para_ix":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "IX"])
		"unir_mbr_ao_aux_e_transferir_para_alu_a":
			adicionar_fila_registrador_interagindo(["AUX", "ULAA"])
		"unir_mbr_ao_aux_e_transferir_para_alu_b":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "ULAB"])
		"dividir_ix_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["IX", "MBR", "AUX"])
		"dividir_pp_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["PP", "MBR", "AUX"])
		"dividir_pc_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["PC", "MBR", "AUX"])
		"dividir_alu_saida_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["ULASaida", "MBR", "AUX"])
		"unir_mbr_ao_aux_e_transferir_para_mar":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "MAR"])
		"unir_mbr_ao_aux_e_transferir_para_pc":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "PC"])
		"unir_mbr_ao_aux_e_transferir_para_ix":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "IX"])
		"unir_mbr_ao_aux_e_transferir_para_alu_a":
			adicionar_fila_registrador_interagindo(["AUX", "ULAA"])
		"unir_mbr_ao_aux_e_transferir_para_alu_b":
			adicionar_fila_registrador_interagindo(["MBR", "AUX", "ULAB"])
		"dividir_ix_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["IX", "MBR", "AUX"])
		"dividir_pp_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["PP", "MBR", "AUX"])
		"dividir_pc_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["PC", "MBR", "AUX"])
		"dividir_alu_saida_e_transferir_para_mbr_e_aux":
			adicionar_fila_registrador_interagindo(["ULASaida", "MBR", "AUX"])
		"transferir_a_para_alu_a":
			adicionar_fila_registrador_interagindo(["A", "ULAA"])
		"transferir_b_para_alu_b":
			adicionar_fila_registrador_interagindo(["B", "ULAB"])
		"transferir_b_para_alu_a":
			adicionar_fila_registrador_interagindo(["B", "ULAA"])
		"transferir_mar_para_alu_a":
			adicionar_fila_registrador_interagindo(["MAR", "ULAA"])
		"transferir_ix_para_alu_b":
			adicionar_fila_registrador_interagindo(["IX", "ULAB"])
		"transferir_mbr_para_alu_b":
			adicionar_fila_registrador_interagindo(["MBR", "ULAB"])
		"transferir_mbr_para_alu_a":
			adicionar_fila_registrador_interagindo(["MBR", "ULAA"])
		"transferir_mar_para_pc":
			adicionar_fila_registrador_interagindo(["MAR", "PC"])
		"transferir_a_para_b":
			adicionar_fila_registrador_interagindo(["A", "B"])
		"transferir_b_para_a":
			adicionar_fila_registrador_interagindo(["B", "A"])
		"transferir_mar_para_pp":
			adicionar_fila_registrador_interagindo(["MAR", "PP"])
		"transferir_pp_para_ix":
			adicionar_fila_registrador_interagindo(["PP", "IX"])
		"transferir_ix_para_a":
			adicionar_fila_registrador_interagindo(["IX", "A"])
		"transferir_ix_para_b":
			adicionar_fila_registrador_interagindo(["IX", "B"])
		"transferir_b_para_aux":
			adicionar_fila_registrador_interagindo(["B", "AUX"])
		"transferir_alu_saida_para_a":
			adicionar_fila_registrador_interagindo(["ULASaida", "A"])
		"transferir_alu_saida_para_b":
			adicionar_fila_registrador_interagindo(["ULASaida", "B"])
		"transferir_alu_saida_para_mar":
			adicionar_fila_registrador_interagindo(["ULASaida", "MAR"])
		"transferir_alu_saida_para_mbr":
			adicionar_fila_registrador_interagindo(["ULASaida", "MBR"])
		"transferir_pp_para_mar":
			adicionar_fila_registrador_interagindo(["PP", "MAR"])
		"transferir_flags_para_mbr":
			adicionar_fila_registrador_interagindo(["Z", "N", "C", "O", "MBR"])
		"transferir_mar_ao_endereco_de_memoria":
			adicionar_fila_registrador_interagindo(["MAR", "MemoriaEndereco"])
		"transferir_valor_da_memoria_ao_aux":
			adicionar_fila_registrador_interagindo(["MemoriaValor", "AUX"])
		"transferir_valor_da_memoria_ao_mbr":
			var valores = obter_info_memorias()
			# Resolvendo animação de leitura da memória
			
			tween_memoria = create_tween()

			var caminho_fluxo_linha = %Linhas.get_node("fluxo_end_selec")
			tween_memoria.tween_property(caminho_fluxo_linha, "visible", true, WAIT_TIME)
			tween_memoria.tween_property(%MemoriaEnderecoAnteriorLabel, "text", valores[0], 0)
			tween_memoria.tween_property(%MemoriaEnderecoButton, "text", valores[1], 0)
			tween_memoria.tween_property(%MemoriaEnderecoPosteriorLabel, "text", valores[2], 0)
			tween_memoria.tween_property(caminho_fluxo_linha, "visible", false, WAIT_TIME)

			caminho_fluxo_linha = %Linhas.get_node("fluxo_leimem")
			tween_memoria.tween_property(caminho_fluxo_linha, "visible", true, WAIT_TIME)
			tween_memoria.tween_property(%MemoriaValorAnteriorLabel, "text", valores[3], 0)
			tween_memoria.tween_property(%MemoriaValorButton, "text", valores[4], 0)
			tween_memoria.tween_property(%MemoriaValorPosteriorLabel, "text", valores[5], 0)
			tween_memoria.tween_property(caminho_fluxo_linha, "visible", false, WAIT_TIME)
			
			await tween_memoria.finished
			
			adicionar_fila_registrador_interagindo(["MemoriaValor", "MBR"])
		"transferir_mbr_para_endereco_selecionado":
			adicionar_fila_registrador_interagindo(["MBR", "MemoriaEndereco"])
		"transferir_aux_para_endereco_selecionado":
			adicionar_fila_registrador_interagindo(["AUX", "MemoriaEndereco"])
		"incrementar_registrador_pc", "iniciar_registrador_pc":
			adicionar_fila_registrador_interagindo(["PC"])
		"incrementar_registrador_mar":
			adicionar_fila_registrador_interagindo(["MAR"])
		"incrementar_registrador_pp", "decrementar_registrador_pp":
			adicionar_fila_registrador_interagindo(["PP"])
		"decrementar_registrador_ix":
			adicionar_fila_registrador_interagindo(["IX"])
		"decrementar_registrador_a", "incrementar_registrador_a":
			adicionar_fila_registrador_interagindo(["A"])
		"calcular_flags":
			for flag in flags_atualizadas:
				registradores_interagindo.append(flag)
			flags_atualizadas.clear()
		"decodificar":
			adicionar_fila_registrador_interagindo(["IR"])
	
	# Demonstração do fluxo
	if typeof(microoperacao_atual) == typeof(Simulador.consultar_microperacao_atual()) and \
		microoperacao_atual == Simulador.consultar_microperacao_atual():
		acender_registradores_interagindo()
		
		var fluxo_microoperacao = %Linhas.find_child("fluxo_" + microoperacao_atual)
		if fluxo_microoperacao:
			fluxo_ligado = fluxo_microoperacao
			caminhar_fluxo(fluxo_microoperacao)
	else:
		# Se microoperacao_atual não combina mais com a microoperação atual,
		# então significa que a microoperação foi saltada e não deve criar um novo fluxo
		pass

func acender_registradores_interagindo() -> void:
	for reg in registradores_interagindo:
		var tw = create_tween()
		tw.tween_property(reg, "modulate", Color.DARK_RED, 0.5).set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(reg, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_LINEAR)
		tw.set_loops()
		tweens_piscar_registradores.append(tw)

func apagar_tweens():
	for tween in tweens_piscar_registradores:
		tween.kill()
	
	if tweens_piscar_registradores:
		for reg in registradores_interagindo:
			reg.modulate = Color.WHITE
		registradores_interagindo.clear()
	
	if fluxo_tween:
		fluxo_tween.kill()

func atualizar_registrador(registrador: String):
	if not Simulador.atualizacao_visual_ativa:
		return
	
	match registrador:
		"A":
			registradores_nos["A"].text = CPU.registrador_a.como_hex(2)
		"B":
			registradores_nos["B"].text = CPU.registrador_b.como_hex(2)
		"PC":
			registradores_nos["PC"].text = CPU.registrador_pc.como_hex(4)
		"IX":
			registradores_nos["IX"].text = CPU.registrador_ix.como_hex(4)
		"PP":
			registradores_nos["PP"].text = CPU.registrador_pp.como_hex(4)
		"MBR":
			registradores_nos["MBR"].text = CPU.registrador_mbr.como_hex(2)
		"AUX":
			registradores_nos["AUX"].text = CPU.registrador_aux.como_hex(2)
		"MAR":
			registradores_nos["MAR"].text = CPU.registrador_mar.como_hex(4)
		"Z":
			registradores_nos["Z"].text = CPU.flag_z.como_hex(1)
		"N":
			registradores_nos["N"].text = CPU.flag_n.como_hex(1)
		"C":
			registradores_nos["C"].text = CPU.flag_c.como_hex(1)
		"O":
			registradores_nos["O"].text = CPU.flag_o.como_hex(1)
		"IR":
			registradores_nos["IR"].text = CPU.registrador_ir.como_hex(2)
		"ULAA":
			registradores_nos["ULAA"].text = CPU.alu_entrada_a.como_hex(4)
		"ULAB":
			registradores_nos["ULAB"].text = CPU.alu_entrada_b.como_hex(4)
		"ULASaida":
			registradores_nos["ULASaida"].text = CPU.alu_saida.como_hex(4)

func caminhar_fluxo(linha_fluxo: Line2D):
	if not linha_fluxo:
		return
	
	linha_fluxo.visible = true
	fluxo_ligado = linha_fluxo

func remover_fluxos():
	if fluxo_ligado:
		fluxo_ligado.visible = false
	
	if tween_memoria:
		tween_memoria.set_speed_scale(10)

func obter_info_memorias():
	var valor = Memoria.endereco_selecionado.como_hex(4)
	var valor_conteudo = Memoria.ler_conteudo_no_endereco_selecionado().como_hex(2)
	
	var dois_antes: Valor = Valor.new(0)
	var um_antes: Valor = Valor.new(0)
	var um_depois: Valor = Valor.new(0)
	var dois_depois: Valor = Valor.new(0)
	
	if Memoria.endereco_selecionado.como_int() - 1 >= 0:
		um_antes = Valor.novo_de_int(Memoria.endereco_selecionado.como_int() - 1)
	
	if Memoria.endereco_selecionado.como_int() - 2 >= 0:
		dois_antes = Valor.novo_de_int(Memoria.endereco_selecionado.como_int() - 2)
	
	if Memoria.endereco_selecionado.como_int() + 1 <= Memoria.TAMANHO_MEMORIA - 1:
		um_depois = Valor.novo_de_int(Memoria.endereco_selecionado.como_int() + 1)
	
	if Memoria.endereco_selecionado.como_int() + 2 <= Memoria.TAMANHO_MEMORIA - 1:
		dois_depois = Valor.novo_de_int(Memoria.endereco_selecionado.como_int() + 2)
	
	var texto_antes = dois_antes.como_hex(4) + "\n" + um_antes.como_hex(4)
	var texto_depois = um_depois.como_hex(4) + "\n" + dois_depois.como_hex(4)
	
	var texto_conteudo_antes = Memoria.ler_conteudo_no_endereco(dois_antes).como_hex() + "\n" + Memoria.ler_conteudo_no_endereco(um_antes).como_hex()
	var texto_conteudo_depois = Memoria.ler_conteudo_no_endereco(um_depois).como_hex() + "\n" + Memoria.ler_conteudo_no_endereco(dois_depois).como_hex()
	
	return [texto_antes, valor, texto_depois, texto_conteudo_antes, valor_conteudo, texto_conteudo_depois]

func fase_foi_alterada(fase: Simulador.Ciclo):
	if Teste.em_modo_multiplos_teste():
		return

	var fase_atual = "Fase atual: " 
	match fase:
		Simulador.Ciclo.BUSCA: fase_atual += "BUSCA"
		Simulador.Ciclo.DECODIFICACAO: fase_atual += "DECODIFICAÇÃO"
		Simulador.Ciclo.ENDERECAMENTO: fase_atual += "ENDEREÇAMENTO"
		Simulador.Ciclo.EXECUCAO: fase_atual += "EXECUÇÃO"
	
	print(fase_atual)

func adicionar_flags_interagindo(registrador: Button):
	flags_atualizadas.append(registrador)

func limpar_flags():
	flags_atualizadas.clear()

func adicionar_fila_registrador_interagindo(fila: Array[String]):
	for reg in fila:
		registradores_interagindo.append(registradores_nos[reg])
