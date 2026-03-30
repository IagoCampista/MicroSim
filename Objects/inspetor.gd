extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func atualizar_tela(elemento: Button):
	var opcode = "???"
	var valor 		: Valor 	= Valor.novo_de_hex(elemento.text)
	var instrucao 	: Instrucao = Montador.desmontar(valor)
	var endereco 	: Valor 	= Valor.novo_de_hex(elemento.name)
	
	if instrucao:
		opcode = "{mnemonico} (endereçamento {enderecamento})".format({
				"mnemonico": instrucao.mnemonico, 
				"enderecamento": instrucao.enderecamento_como_string()
			})
	
	var text = """
	Endereço ([color=gray]{end_hex}[/color]):
		* Hex: [b]{end_hex}[/b]
		* Bin: [b]{end_bin}[/b]
		
	Valor ([color=gray]{valor}[/color]):
		* Hex: [b]{valor}[/b]
		* Bin: [b]{binario}[/b]
		* Como mnemônico: [b]{opcode}[/b]
	""".format({"end_hex": elemento.name, "end_bin": endereco.como_bin() , "valor": elemento.text,
		"binario": valor.como_bin(), "opcode": opcode})
	
	$Label.text = text
