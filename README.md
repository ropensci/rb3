# marketdataBR

Leitura e tratamento dos arquivos de dados de mercado distribuídos no Mercado Financeiro Brasileiro.

## Como usar

A função `read_marketdata` deve ser usada para ler os arquivos.
Os arquivos com nomes fixos como `Indic.txt` e `PUWEB.TXT`, por exemplo, são _interpretados_ pela função `read_marketdata`.

`read_marketdata` retorna um `data.frame` com o conteúdo do arquivo, como observa-se no código abaixo para o arquivo de indicadores financeiros.

```r
indic <- read_marketdata('Indic.txt')
str(indic)
# 'data.frame':	480 obs. of  9 variables:
#  $ Identificação da transação : num  1 2 3 4 5 6 7 8 9 10 ...
#  $ Complemento da transação   : num  1 1 1 1 1 1 1 1 1 1 ...
#  $ Tipo de registro           : num  1 1 1 1 1 1 1 1 1 1 ...
#  $ Data de geração do arquivo : Date, format: "2014-12-11" "2014-12-12" ...
#  $ Grupo do indicador         : Factor w/ 6 levels "Indicadores agropecuários",..: 2 2 2 2 2 2 2 2 2 2 ...
#  $ Código do indicador        : chr  "DE11-B40" "DE11-B40" "DE13-A18" "DE13-A18" ...
#  $ Valor do indicador na data : num  107 107 110 110 102 ...
#  $ Número de decimais do valor: num  4 4 4 4 4 4 4 4 4 4 ...
#  $ Filler                     : chr  "" "" "" "" ...
```

Alguns arquivos são dividos em partes como __cabeçalho__ e __corpo__, e nestes casos `read_marketdata` retorna um `list` contendo um `data.frame` em cada elemento.
O arquivo `PUWEB.TXT`, no código abaixo, é um exemplo.

```r
puweb <- read_marketdata('PUWEB.TXT')
str(puweb)
# List of 2
#  $ Cabeçalho:'data.frame':	1 obs. of  3 variables:
#   ..$ Tipo de registro          : int 1
#   ..$ Data de geração do arquivo: Date[1:1], format: "2015-09-25"
#   ..$ Nome do arquivo           : chr "PUWEB.TXT"
#  $ Corpo    :'data.frame':	170 obs. of  8 variables:
#   ..$ Tipo de registro                  : int [1:170] 2 2 2 2 2 2 2 2 2 2 ...
#   ..$ Código do título                  : int [1:170] 100000 100000 100000 100000 100000 100000 100000 100000 100000 100000 ...
#   ..$ Descrição do título               : Factor w/ 6 levels "LTN","NTNF","LFT",..: 1 1 1 1 1 1 1 1 1 1 ...
#   ..$ Data de emissão do título         : Date[1:170], format: "2014-07-04" "2012-01-06" ...
#   ..$ Data de vencimento do título      : Date[1:170], format: "2015-10-01" "2016-01-01" ...
#   ..$ Valor de mercado em PU            : num [1:170] 998 965 931 898 864 ...
#   ..$ Valor do PU em cenário de estresse: num [1:170] 998 962 924 886 849 ...
#   ..$ Valor de mercado em PU para D+1   : num [1:170] 998 965 932 898 864 ...
```

## Arquivos Tratados

| Arquivo | Fonte | Mercado | Descrição |
| ------- | ----- | ------- | --------- |
| BD_Arbit.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados em Pregão - Parcial |
| BDPrevia.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados em Pregão - Preliminar |
| BD_Final.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados em Pregão - Final |
| BDAfterHour.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados em Pregão - After-Hours (D+1) |
| BDAtual.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados em Pregão - Atualização de Contratos em Aberto |
| BDAjuste.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados em Pregão - Ajustes |
| Indica.txt | BM&FBovespa | Mercado de Derivativos | Indicadores Econômicos e Agropecuários - Parcial |
| Indic.txt | BM&FBovespa | Mercado de Derivativos | Indicadores Econômicos e Agropecuários - Final |
| CONTRCAD.txt | BM&FBovespa | Mercado de Derivativos | Contratos Cadastrados |
| CONTRCAD-IPN.txt | BM&FBovespa | Mercado de Derivativos | Contratos Cadastrados Nova Clearing |
| TaxaSwap.txt | BM&FBovespa | Mercado de Derivativos | Taxas de Mercado para Swaps |
| PUWEB.TXT | BM&FBovespa | Mercado de Títulos Públicos | Preços Referenciais para Títulos Públicos |
| Premio.txt | BM&FBovespa | Mercado de Derivativos | Prêmio de Referência para Opções |
| SupVol.txt | BM&FBovespa | Mercado de Derivativos | Superfície de Volatilidade por Delta |
| Eletro.txt | BM&FBovespa | Mercado de Derivativos | Negócios Realizados no Mercado de Balcão |

<!--

- [ ] Mercado de Títulos Públicos - Cotações
	- Cotacao
- [ ] Mercado de Derivativos - Posições Travadas
	- PosTrav
- [ ] Mercado de Derivativos - Swap Cambial - Mark to Market
	- Market
- [ ] Mercado de Títulos Públicos - Preços Referenciais BM&F para LTN
	- Ltaammdd
- [ ] Mercado de Câmbio - Taxas Praticadas, Parâmetros de Abertura e Operações Contratadas
	- Ctaammdd
- [ ] Mercado de Câmbio - Volume Líquido Compensado
	- Cvaammdd
- [ ] Mercado de Derivativos - Operações Estruturadas de Volatilidade
	- Ref_Vol
- [ ] Mercado de Derivativos - Tarifação para Swaps
	- TarSwap
- [ ] Mercado de Derivativos - Relação de Códigos ISIN para Contratos Derivativos
	- CodISIND
- [ ] Mercado de Derivativos - Relação de Códigos ISIN para Contratos de Swap
	- CodISINS
- [ ] Mercado de Derivativos - Relação de Códigos ISIN para CPRs
	- CodISINS
- [ ] Mercado de Títulos Públicos - Túnel de Negociação para Operações Definitivas a Vista e a Termo (pontos-base)
	- Tdaammdd
- [ ] Mercado de Títulos Públicos - Túnel de Negociação para Operações Compromissadas (pontos-base)
	- Tcaammdd
- [ ] Mercado de Derivativos - Opções Flexíveis - Parâmetros para Determinação de Limites de Preço e Taxa
	- lpaammdd
- [ ] Mercado de Títulos Públicos - Volume Bruto Contratado
	- VolumeBrutoContratado
- [ ] Mercado de Derivativos - GTSLiNe - Fatores de Ponderação
	- Este arquivo contém os fatores de ponderação (fatores K) de risco dos instrumentos utilizado no GTSLine.
- [ ] Mercado de Derivativos - Deltas Opções Padronizadas
	- Deltas
- [ ] Mercado de Derivativos - Swaps Parâmetros para Determinação de Limites de Preço
	- SWaammdd
- [ ] Cadastro de instrumentos - BVBG.028.01 Instruments File
	- Este arquivo contém as características dos instrumentos negociáveis e dos instrumentos aceitos em garantia que são de conhecimento público.
- [ ] Cadastro de instrumentos indicadores - BVBG.029.01 Instruments File
	- Este arquivo contém as características dos instrumentos indicadores de preço utilizados pela BM&FBOVESPA.
- [ ] Cenários de Margem - CORE
	- Este arquivo apresenta os cenários de risco utilizados no modelo CORE com estrutura similar à atual. Devido às diferenças na estrutura dos cenários, apenas os cenários do tipo “Envelope” e para o segundo dia do holding period são carregados.
- [ ] Agrupamento de Instrumentos Padronizados
	- Este arquivo agrupa os instrumentos padronizados com características em comum e que possuem os mesmos parâmetros e mapeamento em fatores primitivos de risco.
- [ ] Parâmetros de Grupos de Instrumentos
	- Este arquivo relaciona os parâmetros de risco aos grupos de instrumentos previamente definidos.
- [ ] Fórmulas de Risco
	- Este arquivo apresenta as fórmulas de risco cadastradas no sistema.
- [ ] Fatores Primitivos de Risco (FPRs)
	- Este arquivo mostra os fatores primitivos de risco cadastrados no sistema, os instrumentos nos quais os FPRs são baseados e seus parâmetros.
- [ ] Mapeamento de Grupos de Instrumentos Padronizados
	- Este arquivo relaciona os grupos de instrumentos padronizados às fórmulas de risco e aos fatores primitivos de risco correspondentes. O qualificador indica a qual parâmetro da fórmula cada FPR corresponde.
- [ ] Mapeamento de Grupos de Instrumentos OTC
	- Este arquivo relaciona os grupos de instrumentos de OTC, com a identificação do instrumento que corresponde ao ativo-objeto, às fórmulas de risco e aos fatores primitivos de risco correspondentes. O qualificador indica a qual parâmetro da fórmula cada FPR corresponde. No caso de swaps, são relacionados dois mapeamentos, correspondentes a cada “ponta” do swap.
- [ ] Margem Teórica Máxima para Posições em Aberto e Valor Mínimo de Ativos Depositados em Garantia
	- Este arquivo apresenta o valor de margem teórica máxima dos instrumentos negociáveis e o valor mínimo de margem de instrumentos aceitos como garantia.
- [ ] Informações Variáveis de Tarifação - BVBG.024.01 Fee Variables
	- Este arquivo contém informações dos valores utilizados como parâmetros nas fórmulas dos cálculos de tarifas.
- [ ] Custo Unitário de Tarifação - BVBG.043.01 Fee Unit Cost
	- Este arquivo contém os valores base dos custos unitários dos clientes normais e HFT periódicos, ou seja, os valores utilizados para clientes que não apresentaram histórico de volume (ADTV) no respectivo período de apuração. O arquivo trará informações de contratos com custos que não dependem do cálculo diário do prazo para seu vencimento, ou seja, todos com exceção dos grupos de taxas de juros.
- [ ] Custo Unitário Diário de Tarifação - BVBG.044.01 Fee Daily Unit Cost
	- Este arquivo contém os valores base dos custos unitários dos clientes normais e HFT periódicos, ou seja, os valores utilizados para clientes que não apresentaram histórico de volume (ADTV) no respectivo período de apuração. O arquivo trará informações de contratos com custos que não dependem do cálculo diário do prazo para seu vencimento, ou seja, todos com exceção dos grupos de taxas de juros.
- [ ] Tarifação para Clientes Alta Frequência - BVBG.026.01 Daily High Frequency Trader
	- Este arquivo contém todas as possibilidades de preços médios e custos unitários aplicáveis a clientes HFT com apuração diária.
- [ ] Cenários do Tipo Spot
	- Este arquivo apresenta os cenários dos fatores primitivos de risco do tipo Spot (valores a vista).
- [ ] Cenários do Tipo Curva
	- Este arquivo apresenta os cenários dos fatores primitivos de risco do tipo Curva (estruturas a termo).
- [ ] Cenários do Tipo Superfície
	- Este arquivo apresenta os cenários dos fatores primitivos de risco do tipo Superfície (estruturas de volatilidade, a termo e por delta ou preço de exercício).

#### Arquivos Descontinuados

- [ ] Mercado de Derivativos - Cenários de Margem para Swaps 
	- Cenarios
- [ ] Mercado de Derivativos - cenário de Margem Desejável no Mercado Agropecuário (Foma) 
	- CAaammdd
- [ ] Mercado de Derivativos - Tarifação para Produtos de Pregão 
	- TarPreg
- [ ] Mercado de Derivativos - Parâmetros de Tarifação - Produtos de Pregão 
	- TarPar
- [ ] Mercado de Derivativos - Áreas para Margem de Ativos Líquidos 
	- RILareas
- [ ] Mercado de Derivativos - Parâmetros de Margem para Ativos Líquidos 
	- RILContratos
- [ ] Mercado de Derivativos - Volatilidade Implícita para Cálculo de Margem de Ativos Líquidos 
	- RILVolatilidade
- [ ] Mercado de Derivativos - Margem Teórica Máxima para Ativos Líquidos 
	- RILMargemMaxima
- [ ] Mercado de Derivativos - Preços de Opções nos Cenários de Estresse de Margem para Ativos Líquidos 
	- RILPrecOpcoes
- [ ] Mercado de Derivativos - Mapeamento de Opções - Cálculo de Margem
	- MAPEAMEN
- [ ] Mercado de Derivativos - Preços de Opções com Ajuste em Cenários de Estresse
	- RILPrecOpcoesAjuste
- [ ] Mercado de Derivativos - Tarifação para Clientes Alta Frequência
	- Este arquivo (Mercado de Derivativos - Tarifação para Clientes Alta Frequência) contém os valores unitários das taxas de emolumentos que serão usados para calcular as taxas cobradas pela BM&FBOVESPA aplicadas aos negócios realizados por investidores com status de HFT (investidores de alta frequência) . São divulgados os valores de emolumentos para operações normais e day trade, bem como as faixas definidas para os diferentes grupos de mercadorias. Este arquivo é divulgado mensalmente, até às 11h do primeiro dia útil do mês.
- [ ] Mercado de Balcão - Cenário para os fatores de risco Preço a Vista
	- Preco
- [ ] Mercado de Balcão - Cenário para os fatores de risco Volatilidade Implícita
	- VolFlex
- [ ] Mercado de Balcão - Cenário para o fator de risco Taxa de Juros
	- Juros
- [ ] Mercado de Balcão - Fatores Delta
	- FDelta
- [ ] Mercado de Balcão - Margem Máxima
	- MM
- [ ] Mercado de Derivativos - Cenários de Margem para Ativos Líquidos
	- CENLIQW

## ANBIMA

- [ ] Taxas Títulos Públicos
	- msaammdd.txt
- [ ] VNA
	- VNA_ddmmaa.txt
	- VNA_ddmmaa.csv
	- VNA_ddmmaa.txml
 -->
