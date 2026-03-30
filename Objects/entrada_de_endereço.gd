extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func _on_focus_exited():
	self.obter_endereco()

func obter_endereco() -> Valor:
	var endereço: Valor = Valor.novo_de_hex(self.text)
	self.text = endereço.como_hex(4)
	return endereço
