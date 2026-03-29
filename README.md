# MicroSim

O MicroSim é um simulador de processador de uma arquitetura customizada simples.

Esse projeto é o resultado do Trabalho de Conclusão de Curso "MicroSim: desenvolvimento de uma arquitetura CISC com simulador pedagógico integrado em linguagem de baixo nível" (disponível em: https://bd.centro.iff.edu.br/jspui/handle/123456789/4995) que apresenta de forma detalhada a aplicação e o código. 

## Tela

A tela é uma ferramenta de visualização dos dados da memória. Ela tem dimensões 64x32 e a fim de reduzir espaço ocupado de memória, ela é monocromática e utiliza 1 bit para representar cada pixel, resultando num total de 2048 bits que equivalem à 256 bytes. Por causa disso, o espaço total livre da memória passa de 4096 bytes para 3840 bytes no caso em que ela for utilizada.
Vale lembrar também que a stack começa no endereço 0xFFF (4095) por padrão, então se a tela for utilizada, deve-se trocar o ponto inicial da stack para começar antes da tela no endereço 0xEFF (3839) usando a instrução LDP no programa, por exemplo.
Se não é desejado utilizar a tela, pode-se apenas a ignorar, não precisando realizar nenhuma operação pois a tela é passiva e só reflete os dados guardados na memória.

## Memória

Quando a aplicação é iniciada, uma memória é gerada automaticamente por padrão se não foi determinada o caminho de um arquivo de memória dentro do aquivo de estado padrão `padrão.sta` que é carregado automaticamente pela aplicação.

Apesar de ser gerada por meio de um algoritmo aleatório, ela sempre utiliza o mesmo valor de *seed*, logo, toda inicialização resultará na exata mesma memória.

## Fluxo de execução de um programa

Para executar um progama, primeiro é necessário digitar o código fonte dele na caixa de Programa. Em seguida, deve-se clicar no botão para salvar o código na memória, que irá montar o código e convertê-lo em bytes que serão armazenados na memória a partir do endereço indicado. O processo de montagem será mais detalhado posteriormente.

Com o código na memória, para iniciar a execução basta indicar o endereço inicial e utilizar os botões de execução no modo que for desejado: avançar apenas uma microoperação, avançar uma instrução ou executar todo o código de uma vez. Essas opções permitem execução na medida em que é desejável para a compreensão do programa pelo usuário.

### Montagem

A rotina de montagem do código lê o código fonte linha a linha, transformando-as em bytes que serão salvos na memória.

O processo de montagem ocorre da seguinte forma: cada linha é passada por um regex que irá extrair informações necessárias para gerar um objeto do tipo `Instrucao`.

Usando de exemplo a linha `LDA#03`: os três primeiros caracteres são extraídos e considerados como a parte do mnemônico nesse comando. Nesse caso, é o mnemônico é `LDA`. O restante da linha, `#03`, é então enviado para uma função que detectará qual é o modo de endereçamento e qual é o parâmetro (se ele existir). Nesse exemplo, o modo de endereçamento será `imediato` por conta da `#` e o parâmetro será `03`. Então sabe-se as seguintes informações sobre a instrução atualmente:

|                   |           |
|:-----------------:|:----------|
| Endereçamento     | imediato  |
| Mnemônico         | LDA       |
| Parâmetro         | 03        |

Esses dados são usados para criar um objeto `Instrucao`. Se a instrução possui parâmetro (ou seja, o modo de endereçamento não é `implícito`), é necessário antes determinar qual é o tamanho do parâmetro. O único caso que é necessário fazer isso é no modo de endereçamento `imediato`, pois em todos os outros modos (novamente, excluindo o `implícito` que não tem parâmetro) o parâmetro sempre será um endereço de memória que sempre tem dois bytes.

No modo `imediato`, é possível ter um ou dois bytes como parâmetro e isso é determinado por cada instrução em si. O modo de endereçamento apenas não é o bastante para obter essa informação. No exemplo atual, a instrução foi identificada como `LDA` no modo `imediato`, e nesse caso o parâmetro sempre será um dado de 1 byte pois essa instrução irá carregar um valor no registrador `A` que suporta apenas 1 byte. Já no caso da instrução `LDP` no modo `imediato`, o parâmetro sempre terá 2 bytes, pois essa instrução é realizada sobre o `registrador PP` que tem 2 bytes.

Continuando o exemplo de montagem: durante a criação do objeto `Instrucao`, o mnemônico é utilizado para consultar todas as instruções existentes no processador a fim de determinar qual é opcode referente à instrução no modo de endereçamento detectado e qual é o tamanho do parâmetro no modo imediato. O objeto então possui as seguintes informações:

|                   |           |
|:-----------------:|:----------|
| Endereçamento     | imediato  |
| Mnemônico         | LDA       |
| Parâmetro         | 03        |
| Opcode            | 20        |
| Tamanho do Dado   | 1         |

Munido dessas informações, agora é possível invocar uma rotina que retorna os bytes que descrevem essa instrução. Então será retornado dois bytes: `20 03`. Esses bytes serão armazenados na memória na posição atual do registrador contador de programa `PC`.

No caso da instrução `LDP#78`, por exemplo, os bytes resultantes serão `2B 00 78`.

### Desmontagem

[WIP]

## Extensões de arquivos

### .prg

[WIP]

É um arquivo de texto simples onde cada linha possui uma instrução num formato suportado pela aplicação (por exemplo, `LDA #10`).

### .sta

[WIP]

É um arquivo de estado. Sua estrutura segue o padrão de arquivos de inicialização (*.ini*) e configuração (*.cfg*). Ele suporta duas seções: `inicio` e `fim`. A seção "inicio" é sempre obrigatória, ela descreve qual será o estado inicial que o simulador deve ter e pode substituir o estado atual se desejado. O simulador irá carregar todos os seus dados com as informações dessa seção. Já a seção "fim" é opcional, pois é usada apenas em casos de teste. 

Idealmente, é `recomendado` preencher todos os campos com algum valor válido para garantir estabilidade da aplicação. Porém, todos os campos possuem o valor inicial "0" caso não sejam definidos.

Como mencionado anteriormente, arquivos de estado também são usados em testes, que começa com o estado inicial definido pela seção "inicio", e o estado final do simulador é comparado com os valores da seção "fim".

Para inicializar células de memória na seção `inicio`, o campo aceito atualmente é `memoria.substituicoes`. O campo `memoria` sem sufixo é usado na seção `fim` para validar o conteúdo esperado da memória após a execução do teste.

### .MEM

[WIP]

## Incrementação/Decrementação

As operações de incremento e decremento foram modificadas e funcionam de forma diferente do que o MICRO3. Todas as operações relacionadas são sempre enviadas à `ULA`, ao contrário do que era feita anteriormente, que ocasionava incrementação diretamente no próprio registrador. Isso também causa mudança no cálculo de flags, que vai ser mais abordado na seção sobre `Flags`. Para que essa mudança funcione, todas as instruções devem ser alteradas para que não existam microoperações do tipo `incrementar_registrador_??` para se tornarem microoperações na `ULA`, por exemplo: `"transferir_??_para_alu_a", "incrementar_um_na_alu_a_16_bits", "transferir_alu_saida_para_??"`. A mesma coisa ocorre na operação de decrementação.

## Flags

O comportamento de quando as flags são atualizadas foi alterado: as flags só são atualizadas quando uma operação na `ULA` é performada. A operação em si dita quais flags são atualizadas. No trabalho de Kleber e Lucas ele dizem que:

```
Um diferencial da arquitetura MICRO3 é que as instruções de carregamento também atualizam as flags. Essa funcionalidade foi implementada em VHDL ao direcionar
a instrução de carregamento para passar pela ULA, a qual é responsável por modificar as flags. Para garantir que o operando permaneça inalterado, realiza-se uma operação de soma com zero.
```

Atualmente, foi decidido por remover as atualizações de flags após carregamento. Uma das razões é que ainda não foi determinado se isso sempre é verdade, pois na instrução `XAB` não há atualização das flags; então teria que ser explorado se isso só ocorre especificamente durante o carregamento vindo da memória ou algo assim.
Outra razão da remoção foi por conta da decisão que apenas a `ULA` pode provocar a verificação das flags. Mas se for desejável manter o mesmo comportamento (após entendê-lo melhor), então seria possível usar a mesma abordagem do trabalho mencionado: adicionar microoperações nas intruções que provoque uma soma com zero na `ULA`, causando atualização nas flags que não cause nenhuma perturbação na execução.

Também foi adotada uma separação explícita entre operações aritméticas de dados e operações internas de endereçamento. As instruções que operam sobre os registradores de 8 bits `A` e `B`, como `ADA`, `ADB`, `SUA` e `SUB`, agora calculam `Z`, `N`, `C` e `O` considerando apenas 1 byte. Isso evita que resultados como `0x00 - 0x01 = 0xFF` percam a sinalização esperada de negativo por serem avaliados como se fossem números de 16 bits.

Em contrapartida, somas internas usadas apenas para cálculo de endereço, como a composição de `MAR + IX` durante endereçamentos indexados, continuam sendo realizadas em 16 bits e não atualizam flags. Essa separação foi necessária para impedir que cálculos de endereço interfiram no estado lógico do programa e, ao mesmo tempo, manter coerência nas instruções aritméticas visíveis ao usuário.

Na prática, isso significa que as flags passam a representar o resultado da última operação aritmética relevante do programa, e não efeitos colaterais de microoperações de navegação na memória. Um exemplo é `SUB #01` com `B = 00`, cujo resultado final é `FF`; nesse caso, o comportamento esperado passa a ser `Z = 0`, `N = 1`, `C = 0` e `O = 0`.

### Descontinuidade (o)

A flag de descontinuidade aponta quando, após uma operação na `ULA`, um valor muda de sinal de forma inesperada. Isso ocorre, por exemplo, quando o bit que está sendo usado como sinal de um byte é alterado por conta de uma operação aritmética de forma não desejada. Um exemplo é quando somamos um ao valor positivo `0x7F` (`0b01111111`). O resultado será o valor negativo `0x80` (`0b10000000`). Como não é esperado que uma soma cause a troca do sinal desse valor, então a flag de descontinuidade se torna 1.

### Vai um (c)

A flag de vai um ocorre quando uma operação feita na `ULA` irá "emprestar" um bit para uma casa e ele não será utilizado ou quando ele vai precisar "pegar emprestado" um bit inicial que ele não possui.
Um exemplo é quando é incrementado um para o valor de um byte `0xFF`. O resultado seria `0x100` (`0b100000000`). Como esse valor é maior do que um byte consegue guardar, então esse bit a mais vai ser descartado (foi emprestado mas sobrou).
O mesmo acontece quando temos `0x00` e vamos substrair um. Ele vai precisar de um bit emprestado, já que ele não possui nenhum em si. Logo, a flag é ativada.


## Notas

* No MICRO3, apesar da execução da instrução `CAL` produzir o resultado correto, a seção de que realiza a demonstração da simulação da execução da instrução não está correta. A implementação dos passos da simulação não levou ao mesmo resultado da execução. Logo, foi necessário o desenvolvimento do zero dos microcódigos referentes à essa instrução em particular.

* Talvez trocar "transferir_ix_para_a", "transferir_ix_para_b" para ser apenas uma operação. Vai depender se houver outros casos em que só um é utilizado.

* Alguns registradores e flags foram renomeados. As flags eram chamadas de `z` (zero), `n` (negativo), `r` (carry, ou 'vai um') e `d` (descontinuidade ou excedente). Nesse projeto, as flags `r` e `d` foram alteradas para `c` (carry) e `o` (overflow) para assim ficarem com os nomes conhecidos na literatura inglesa. Esse tema se extendeu aos registradores: o `DON` se tornou `MBR` (memory buffer register), o `RAD` se tornou o `MAR` (memory address register), o `CO` (contador ordinal) se tornou `PC` (program counter) e o `DCOD` (decoficador) se tornou `IR` (instruction register).
A flag de overflow (também conhecido como "transbordo" e "estouro") é chamada de `v` em algumas literaturas. Stallings chama de `OF`.
Seria bom rever as menções nos recursos das instruções os nomes das flags e registradores. Também, os mnemônicos das instruções em si são referências aos nomes antigos das operações. Seria bom analisar se é necessário renomeá-los para nomes mais usados em literaturas ou se já estão a seguindo.

* Na instrução `DIV` é explicitado que os registradores `A` e `B` são concatenados e enviados à `ULA entrada A` para formar o dividendo (ou seja, um número de 2 bytes), o parâmetro da instrução é enviado à `ULA entrada B` como o divisor, e a divisão ocorre. Na saída, apenas o nibble superior da divisão é mantido, enquanto o inferior é substituído pelo valor do resto. Esse número é então dividido e enviado para eventualmente popular os registradores `A` e `B`.
Após realizar alguns testes manuais e consultas, parece que o cálculo de divisão do Micro3 está incorreto. Então o cálculo desenvolvido nessa aplicação vai ser utilizada em seu lugar, logo, os resultados entre os simuladores serão diferentes.

* O fluxo de execução também passou a interromper de forma segura os casos em que a decodificação não encontra uma instrução válida para o opcode lido na memória. Antes dessa correção, a máquina de estados ainda avançava para a fase de endereçamento, o que causava acesso a propriedades de uma instrução nula e resultava em erro durante a execução visual. Com a alteração, a simulação é encerrada e retorna para um estado suspenso sem prosseguir para as fases seguintes.

## Referências

* [Documentação dos comandos do Micro3](referência.md), uma das maiores referências e inspirações pro projeto. As instruções desse simulador são baseadas nas existentes do MICRO3.
