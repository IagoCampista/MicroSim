extends Node


func incrementar_registrador_pc() -> void:
	var parcela_um	: int = CPU.registrador_pc.como_int()
	var parcela_dois: int = 1
	var valor: Valor = self._realizar_adicao(parcela_um, parcela_dois, 2, false)
	CPU.atualizar_registrador_pc(valor)

func incrementar_registrador_mar() -> void:
	var parcela_um	: int = CPU.registrador_mar.como_int()
	var parcela_dois: int = 1
	var valor: Valor = self._realizar_adicao(parcela_um, parcela_dois, 2, false)
	CPU.atualizar_registrador_mar(valor)

func incrementar_registrador_pp() -> void:
	var parcela_um	: int = CPU.registrador_pp.como_int()
	var parcela_dois: int = 1
	var valor: Valor = self._realizar_adicao(parcela_um, parcela_dois, 2, false)
	CPU.atualizar_registrador_pp(valor)

func incrementar_registrador_ix() -> void:
	var parcela_um	: int = CPU.registrador_ix.como_int()
	var parcela_dois: int = 1
	var valor: Valor = self._realizar_adicao(parcela_um, parcela_dois, 2, false)
	CPU.atualizar_registrador_ix(valor)

func incrementar_registrador_a() -> void:
	var parcela_um	: int = CPU.registrador_a.como_int()
	var parcela_dois: int = 1
	var valor: Valor = self._realizar_adicao(parcela_um, parcela_dois, 1, false)
	CPU.atualizar_registrador_a(valor)

func incrementar_registrador_b() -> void:
	var parcela_um	: int = CPU.registrador_b.como_int()
	var parcela_dois: int = 1
	var valor: Valor = self._realizar_adicao(parcela_um, parcela_dois, 1, false)
	CPU.atualizar_registrador_b(valor)

func decrementar_registrador_pp() -> void:
	var minuendo	: int 	= CPU.registrador_pp.como_int()
	var subtraendo	: int 	= self._realizar_complemento_a_dois(Valor.new(1)).como_int()
	var valor		: Valor = self._realizar_adicao(minuendo, subtraendo, 2, false)
	CPU.atualizar_registrador_pp(valor)

func decrementar_registrador_ix() -> void:
	var minuendo	: int 	= CPU.registrador_ix.como_int()
	var subtraendo	: int 	= self._realizar_complemento_a_dois(Valor.new(1)).como_int()
	var valor		: Valor = self._realizar_adicao(minuendo, subtraendo, 2, false)
	CPU.atualizar_registrador_ix(valor)

func decrementar_registrador_a() -> void:
	var minuendo	: int 	= CPU.registrador_a.como_int()
	var subtraendo	: int 	= self._realizar_complemento_a_dois(Valor.new(1)).como_int()
	var valor		: Valor = self._realizar_adicao(minuendo, subtraendo, 1, false)
	CPU.atualizar_registrador_a(valor)

func decrementar_registrador_b() -> void:
	var minuendo	: int 	= CPU.registrador_b.como_int()
	var subtraendo	: int 	= self._realizar_complemento_a_dois(Valor.new(1)).como_int()
	var valor		: Valor = self._realizar_adicao(minuendo, subtraendo, 1, false)
	CPU.atualizar_registrador_b(valor)

func transferir_pc_para_mar() -> void:
	CPU.atualizar_registrador_mar(CPU.registrador_pc)

func transferir_mbr_para_ir() -> void:
	CPU.atualizar_registrador_ir(CPU.registrador_mbr)

func transferir_mbr_para_a() -> void:
	CPU.atualizar_registrador_a(CPU.registrador_mbr)

func transferir_mbr_para_b() -> void:
	CPU.atualizar_registrador_b(CPU.registrador_mbr)

func transferir_aux_para_b() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.registrador_aux)
	CPU.atualizar_registrador_b(valor)

func transferir_a_para_mbr() -> void:
	CPU.atualizar_registrador_mbr(CPU.registrador_a)

func transferir_b_para_mbr() -> void:
	CPU.atualizar_registrador_mbr(CPU.registrador_b)

func transferir_a_para_alu_a() -> void:
	CPU.atualizar_alu_entrada_a(CPU.registrador_a)

func transferir_b_para_alu_b() -> void:
	CPU.atualizar_alu_entrada_b(CPU.registrador_b)
	
func transferir_b_para_alu_a() -> void:
	CPU.atualizar_alu_entrada_a(CPU.registrador_b)

func transferir_mar_para_alu_a() -> void:
	CPU.atualizar_alu_entrada_a(CPU.registrador_mar)

func transferir_ix_para_alu_b() -> void:
	CPU.atualizar_alu_entrada_b(CPU.registrador_ix)
	
func transferir_mbr_para_alu_b() -> void:
	CPU.atualizar_alu_entrada_b(CPU.registrador_mbr)
	
func transferir_mbr_para_alu_a() -> void:
	CPU.atualizar_alu_entrada_a(CPU.registrador_mbr)

func transferir_mar_para_pc() -> void:
	CPU.atualizar_registrador_pc(CPU.registrador_mar)

func transferir_a_para_b() -> void:
	CPU.atualizar_registrador_b(CPU.registrador_a)

func transferir_b_para_a() -> void:
	CPU.atualizar_registrador_a(CPU.registrador_b)

func transferir_mar_para_pp() -> void:
	CPU.atualizar_registrador_pp(CPU.registrador_mar)

func transferir_pp_para_ix() -> void:
	CPU.atualizar_registrador_ix(CPU.registrador_pp)

func transferir_ix_para_a() -> void:
	var resultado: PackedStringArray = CPU.registrador_ix.como_hex_array()
	var nibble_inferior: String = resultado[-1]
	var valor: Valor = Valor.novo_de_hex(nibble_inferior)
	CPU.atualizar_registrador_a(valor)

func transferir_ix_para_b() -> void:
	var resultado: PackedStringArray = CPU.registrador_ix.como_hex_array()
	var nibble_superior: String = resultado[0]
	var valor: Valor = Valor.novo_de_hex(nibble_superior)
	CPU.atualizar_registrador_b(valor)

func transferir_b_para_aux() -> void:
	CPU.atualizar_registrador_aux(CPU.registrador_b)
	
func transferir_alu_saida_para_a() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	var resultado: Valor = self._filtrar_valor(valor, 1)
	CPU.atualizar_registrador_a(resultado)

func transferir_alu_saida_para_b() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	var resultado: Valor = self._filtrar_valor(valor, 1)
	CPU.atualizar_registrador_b(resultado)

func transferir_alu_saida_para_mar() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	var resultado: Valor = self._filtrar_valor(valor, 2)
	CPU.atualizar_registrador_mar(resultado)

func transferir_alu_saida_para_mbr() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	var resultado: Valor = self._filtrar_valor(valor, 2)
	CPU.atualizar_registrador_mbr(resultado)

func transferir_pp_para_mar() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.registrador_pp)
	CPU.atualizar_registrador_mar(valor)

func transferir_flags_para_mbr() -> void:
	var registrador_flag: PackedStringArray = ['0', '0', CPU.flag_o.como_hex(1), 
	CPU.flag_c.como_hex(1), CPU.flag_n.como_hex(1), CPU.flag_z.como_hex(1), '0', '0']
	var flag_como_int: int = "".join(registrador_flag).bin_to_int()
	var resultado: Valor = Valor.new(flag_como_int)
	CPU.atualizar_registrador_mbr(resultado)

func transferir_pp_para_alu_a() -> void:
	var resultado: Valor = Valor.novo_de_valor(CPU.registrador_pp)
	CPU.atualizar_alu_entrada_a(resultado)

func transferir_alu_saida_para_pp() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	CPU.atualizar_registrador_pp(valor)

func transferir_pc_para_alu_a() -> void:
	CPU.atualizar_alu_entrada_a(CPU.registrador_pc)

func transferir_alu_saida_para_pc() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	CPU.atualizar_registrador_pc(valor)

func transferir_ix_para_alu_a() -> void:
	CPU.atualizar_alu_entrada_a(CPU.registrador_ix)

func transferir_alu_saida_para_ix() -> void:
	var valor: Valor = Valor.novo_de_valor(CPU.alu_saida)
	CPU.atualizar_registrador_ix(valor)

func transferir_mar_ao_endereco_de_memoria() -> void:
	Memoria.endereco_selecionado = Valor.novo_de_valor(CPU.registrador_mar)

func transferir_valor_da_memoria_ao_aux() -> void:
	var valor = Memoria.ler_conteudo_no_endereco_selecionado()
	CPU.atualizar_registrador_aux(valor)

func transferir_valor_da_memoria_ao_mbr() -> void:
	var valor = Memoria.ler_conteudo_no_endereco_selecionado()
	CPU.atualizar_registrador_mbr(valor)

func transferir_mbr_para_endereco_selecionado() -> void:
	Memoria.atualizar_valor_no_endereco_selecionado(CPU.registrador_mbr)

func transferir_aux_para_endereco_selecionado() -> void:
	Memoria.atualizar_valor_no_endereco_selecionado(CPU.registrador_aux)

func adicao_alu_a_alu_b() -> void:
	var parcela_um	: int 	= CPU.alu_entrada_a.como_int()
	var parcela_dois: int 	= CPU.alu_entrada_b.como_int()
	var resultado	: Valor = self._realizar_adicao(parcela_um, parcela_dois, 1, true)
	CPU.atualizar_alu_saida(resultado)

func adicao_alu_a_alu_b_com_carry() -> void:
	var parcela_um	: int 	= CPU.alu_entrada_a.como_int()
	var parcela_dois: int 	= CPU.alu_entrada_b.como_int() + CPU.flag_c.como_int()
	var resultado	: Valor = self._realizar_adicao(parcela_um, parcela_dois, 1, true)
	CPU.atualizar_alu_saida(resultado)

func adicao_alu_a_alu_b_16_bits() -> void:
	var parcela_um	: int 	= CPU.alu_entrada_a.como_int()
	var parcela_dois: int 	= CPU.alu_entrada_b.como_int()
	var resultado	: Valor = self._realizar_adicao(parcela_um, parcela_dois, 2, false)
	CPU.atualizar_alu_saida(resultado)

func unir_mbr_ao_aux_e_transferir_para_mar() -> void:
	var resultado: Valor = Valor.novo_de_valor(CPU.registrador_mbr)
	resultado.somar_int(CPU.registrador_aux.como_int() << 8)
	CPU.atualizar_registrador_mar(resultado)

func unir_mbr_ao_aux_e_transferir_para_pc() -> void:
	var resultado: Valor = self._operacao_de_uniao_mbr_ao_aux()
	CPU.atualizar_registrador_pc(resultado)

func unir_mbr_ao_aux_e_transferir_para_ix() -> void:
	# TODO: nesse caso, mbr e aux são concatenados ao contrário por alguma razão
	var resultado: Valor = Valor.novo_de_valor(CPU.registrador_mbr)
	resultado.somar_int(CPU.registrador_aux.como_int() << 8)
	CPU.atualizar_registrador_ix(resultado)

func unir_mbr_ao_aux_e_transferir_para_alu_a() -> void:
	var resultado: Valor = self._operacao_de_uniao_mbr_ao_aux()
	CPU.atualizar_alu_entrada_a(resultado)

func unir_mbr_ao_aux_e_transferir_para_alu_b() -> void:
	var resultado: Valor = Valor.novo_de_valor(CPU.registrador_mbr)
	resultado.somar_int(CPU.registrador_aux.como_int() << 8)
	CPU.atualizar_alu_entrada_b(resultado)

func dividir_ix_e_transferir_para_mbr_e_aux() -> void:
	var registrador: PackedByteArray = CPU.registrador_ix.como_byte_array(4)
	CPU.atualizar_registrador_aux(Valor.new(registrador[0]))
	CPU.atualizar_registrador_mbr(Valor.new(registrador[1]))

func dividir_pp_e_transferir_para_mbr_e_aux() -> void:
	var registrador: PackedByteArray = CPU.registrador_pp.como_byte_array(4)
	CPU.atualizar_registrador_aux(Valor.new(registrador[0]))
	CPU.atualizar_registrador_mbr(Valor.new(registrador[1]))

func dividir_pc_e_transferir_para_mbr_e_aux() -> void:
	var registrador: PackedByteArray = CPU.registrador_pc.como_byte_array(4)
	CPU.atualizar_registrador_mbr(Valor.new(registrador[0]))
	CPU.atualizar_registrador_aux(Valor.new(registrador[1]))

func dividir_alu_saida_e_transferir_para_mbr_e_aux() -> void:
	var registrador: PackedByteArray = CPU.alu_saida.como_byte_array(4)
	CPU.atualizar_registrador_mbr(Valor.new(registrador[0]))
	CPU.atualizar_registrador_aux(Valor.new(registrador[1]))

func operação_de_complemento_a_dois_na_alu_8_bits() -> void:
	var valor		: Valor = self._realizar_complemento_a_dois(CPU.alu_entrada_a)
	var resultado	: Valor = self._filtrar_valor(valor, 1)
	CPU.verificar_flag_z(resultado)
	CPU.verificar_flag_n(resultado, 1)
	CPU.atualizar_alu_saida(resultado)

func operação_de_complemento_a_um_na_alu_8_bits() -> void:
	var valor		: Valor = self._realizar_complemento_a_um(CPU.alu_entrada_a)
	var resultado	: Valor = self._filtrar_valor(valor, 1)
	CPU.verificar_flag_z(resultado)
	CPU.verificar_flag_n(resultado, 1)
	CPU.atualizar_alu_saida(resultado)

func realizar_e_logico_alu_a_alu_b():
	var resultado: int = CPU.alu_entrada_a.como_int() & CPU.alu_entrada_b.como_int()
	var valor = Valor.new(resultado)
	CPU.atualizar_alu_saida(valor)

func realizar_ou_logico_alu_a_alu_b():
	var resultado: int = CPU.alu_entrada_a.como_int() | CPU.alu_entrada_b.como_int()
	var valor = Valor.new(resultado)
	CPU.atualizar_alu_saida(valor)

func comparar_alu_a_com_alu_b_8_bits() -> void:
	var minuendo: int = CPU.alu_entrada_a.como_int()
	var subtraendo: Valor = self._realizar_complemento_a_dois(CPU.alu_entrada_b)
	var resultado: Valor = self._realizar_adicao(minuendo, self._filtrar_valor(subtraendo, 1).como_int(), 1, true)
	CPU.atualizar_alu_saida(resultado)

func comparar_alu_a_com_alu_b_16_bits() -> void:
	var minuendo: int = CPU.alu_entrada_a.como_int()
	var subtraendo: Valor = self._realizar_complemento_a_dois(CPU.alu_entrada_b)
	var resultado: Valor = self._realizar_adicao(minuendo, self._filtrar_valor(subtraendo, 2).como_int(), 2, true)
	CPU.atualizar_alu_saida(resultado)

func realizar_divisao_na_alu():
	var dividendo	: int = CPU.alu_entrada_a.como_int()
	var divisor		: int = CPU.alu_entrada_b.como_int()

	if divisor == 0:
		print("Erro de divisão por zero")
		Simulador.finalizar_execucao(false)
		return

	var resto			: int 				= dividendo % divisor
	var quociente		: Valor 			= Valor.new(floori(dividendo / float(divisor)))
	var resultado_array	: PackedByteArray 	= quociente.como_byte_array(2)
	var valor			: Valor 			= Valor.novo_de_byte_array([resultado_array[0], resto])
	var resultado		: Valor 			= self._filtrar_valor(valor, 2)

	CPU.verificar_flag_z(resultado)
	CPU.verificar_flag_n(resultado, 2)
	CPU.atualizar_alu_saida(resultado)

func realizar_multiplicacao_na_alu_16_bits():
	var fator_um	: int = CPU.alu_entrada_a.como_int()
	var fator_dois	: int = CPU.alu_entrada_b.como_int()
	var produto		: Valor = Valor.new(fator_um * fator_dois)
	CPU.verificar_flag_c(produto, 2)
	var resultado: Valor = self._filtrar_valor(produto, 2)
	CPU.verificar_flag_z(resultado)
	CPU.verificar_flag_n(resultado, 2)
	CPU.atualizar_alu_saida(resultado)

func se_ix_diferente_de_zero():
	return not CPU.registrador_ix.igual(Valor.new(0))

func se_flag_z_igual_um() -> bool:
	return CPU.flag_z.como_int() == 1

func se_flag_z_igual_zero() -> bool:
	return CPU.flag_z.como_int() == 0

func se_flag_n_igual_um() -> bool:
	return CPU.flag_n.como_int() == 1

func se_flag_n_igual_zero() -> bool:
	return CPU.flag_n.como_int() == 0

func se_flags_z_n_ambas_zero() -> bool:
	return CPU.flag_z.como_int() == 0 and CPU.flag_n.como_int() == 0

func se_flag_n_igual_um_ou_flag_z_igual_um() -> bool:
	return CPU.flag_n.como_int() == 1 or CPU.flag_z.como_int() == 1

func se_flag_c_igual_um() -> bool:
	return CPU.flag_c.como_int() == 1

func se_flag_o_igual_um() -> bool:
	return CPU.flag_o.como_int() == 1

func atribuir_um_a_flag_c():
	CPU.atualizar_flag_c(Valor.new(1))

func atribuir_um_a_flag_o():
	CPU.atualizar_flag_o(Valor.new(1))

func atribuir_zero_a_flag_c():
	CPU.atualizar_flag_c(Valor.new(0))

func atribuir_zero_a_flag_o():
	CPU.atualizar_flag_o(Valor.new(0))

func _operacao_de_uniao_mbr_ao_aux() -> Valor:
	var byte_array: PackedByteArray = [
		CPU.registrador_mbr.como_int(),
		CPU.registrador_aux.como_int()
	]
	var resultado: Valor = Valor.novo_de_byte_array(byte_array)
	return resultado

func decodificar() -> void:
	Simulador.instrucao_atual = Montador.desmontar(CPU.registrador_ir)
	
	# se não a instrução não existe
	if not Simulador.instrucao_atual:
		print("Instrução inválida. Encerrando execução.")
		Simulador.finalizar_execucao()

func _realizar_complemento_a_um(valor: Valor) -> Valor:
	var resultado: int = ~valor.como_int()
	return Valor.new(resultado)

func _realizar_complemento_a_dois(valor: Valor) -> Valor:
	var resultado: int = self._realizar_complemento_a_um(valor).como_int()
	return Valor.new(resultado + 1)

func _filtrar_valor(valor : Valor, bytes: int) -> Valor:
	var filtro 		: int = 0xFFFF if (bytes == 2) else 0xFF
	var resultado 	: int = valor.como_int() & filtro
	return Valor.new(resultado)

func _realizar_adicao(parcela_um: int, parcela_dois: int, bytes: int=1, atualizar_flags: bool=true) -> Valor:
	var total: Valor = Valor.new(parcela_um + parcela_dois)
	if atualizar_flags:
		CPU.verificar_flag_c(total, bytes)
	var resultado: Valor = self._filtrar_valor(total, bytes)
	if atualizar_flags:
		CPU.verificar_flag_z(resultado)
		CPU.verificar_flag_n(resultado, bytes)
		CPU.verificar_flag_o(parcela_um, parcela_dois, resultado.como_int(), bytes)
	return resultado

func _incrementar_e_filtrar_valor(parcela_um: int, parcela_dois: int, bytes: int=1):
	var total: Valor = Valor.new(parcela_um + parcela_dois)
	return self._filtrar_valor(total, bytes)
