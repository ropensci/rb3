library(rb3)
library(tidyverse)
library(bizdays)

# Os setores de empresas utilizados pelo mercado financeiro geralmente seguem classificações padronizadas, como o **Global Industry Classification Standard (GICS)** ou outras classificações amplamente aceitas. Abaixo estão os setores mais comuns:

# ### Setores de Empresas no Mercado
# 1. **Energy** (Energia)
#    - Empresas de petróleo, gás, biocombustíveis e energia renovável.

# 2. **Materials** (Materiais)
#    - Empresas de materiais básicos, como mineração, produtos químicos e construção.

# 3. **Industrials** (Industriais)
#    - Empresas de bens industriais, transporte, manufatura e equipamentos.

# 4. **Consumer Discretionary** (Consumo Discricionário)
#    - Empresas de bens e serviços não essenciais, como varejo, automóveis e lazer.

# 5. **Consumer Staples** (Consumo Básico)
#    - Empresas de bens e serviços essenciais, como alimentos, bebidas e produtos de higiene.

# 6. **Health Care** (Saúde)
#    - Empresas de produtos farmacêuticos, biotecnologia e equipamentos médicos.

# 7. **Financials** (Financeiro)
#    - Bancos, seguradoras, corretoras e outras instituições financeiras.

# 8. **Information Technology** (Tecnologia da Informação)
#    - Empresas de software, hardware, semicondutores e serviços de TI.

# 9. **Communication Services** (Serviços de Comunicação)
#    - Empresas de telecomunicações, mídia e entretenimento.

# 10. **Utilities** (Utilidades)
#     - Empresas de serviços públicos, como energia elétrica, gás e água.

# 11. **Real Estate** (Imobiliário)
#     - Empresas de propriedades comerciais, residenciais e fundos imobiliários.

# 12. **Miscellaneous** (Diversos)
#     - Empresas que não se enquadram claramente em nenhum dos setores acima.

# ### Observação
# Esses setores podem variar ligeiramente dependendo da bolsa de valores ou do mercado específico. No caso do Brasil, a B3 utiliza uma classificação semelhante, mas com algumas adaptações locais. Por exemplo, setores como "Petróleo, Gás e Biocombustíveis" podem ser destacados separadamente.

fetch_marketdata("b3-indexes-current-portfolio", index = c("SMLL", "IBOV", "IBXL", "IBXX", "IBRA"))

template_dataset("b3-indexes-current-portfolio") |>
  filter(index == "IBOV") |>
  collect() |>
  mutate(
    # Extrai o texto antes e depois do "/" para criar as colunas sector e subsector
    sector = str_extract(segment, "^[^/]+") |> str_trim(),
    subsector = str_extract(segment, "(?<=/ ).*") |> str_trim(),
    # Normaliza os nomes dos setores
    sector = sector |>
      str_to_lower() |> # Converte para minúsculas
      stringi::stri_trans_general("Latin-ASCII") |> # Remove acentos
      str_replace_all("\\s+", " ") |> # Remove espaços extras
      str_trim() |> # Remove espaços no início e no fim
      str_replace_all("indls|industriais", "industriais") |> # Corrige inconsistências
      str_replace_all("cons n basico|cons n básico", "consumo não básico") |> # Unifica nomes
      str_replace_all("cons n ciclico|cons n cíclico", "consumo não cíclico") |> # Unifica nomes
      str_replace_all("consumo cíclico", "consumo cíclico") |> # Corrige inconsistências
      str_replace_all("financ e outros|financeiro e outros", "financeiro e outros") |> # Unifica nomes
      str_replace_all("utilidade públ", "utilidade pública"), # Corrige inconsistências
    # Mapeia os nomes dos setores para inglês
    sector = case_when(
      sector == "industriais" ~ "Industrials",
      sector == "bens industriais" ~ "Industrials",
      sector == "consumo não básico" ~ "Consumer Discretionary",
      sector == "consumo não cíclico" ~ "Consumer Staples",
      sector == "consumo cíclico" ~ "Consumer Cyclical",
      sector == "consumo ciclico" ~ "Consumer Cyclical",
      sector == "financeiro e outros" ~ "Financials",
      sector == "utilidade pública" ~ "Utilities",
      sector == "utilidade publica" ~ "Utilities",
      sector == "utilidade publ" ~ "Utilities",
      sector == "saúde" ~ "Health Care",
      sector == "saude" ~ "Health Care",
      sector == "tecnologia da informação" ~ "Information Technology",
      sector == "tec.informacao" ~ "Information Technology",
      sector == "comput e equips" ~ "Information Technology",
      sector == "materiais básicos" ~ "Basic Materials",
      sector == "mats basicos" ~ "Basic Materials",
      sector == "petróleo, gás e biocombustíveis" ~ "Energy",
      sector == "petroleo, gas e biocombustiveis" ~ "Energy",
      sector == "diversos" ~ "Miscellaneous",
      sector == "telecomunicacao" ~ "Communication Services",
      TRUE ~ sector # Mantém o nome original se não houver mapeamento
    )
  ) |>
  group_by(sector) |>
  summarise(asset_part = sum(asset_part, na.rm = TRUE)/100) |>
  arrange(sector) |>
  ggplot(aes(x = sector, y = asset_part)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = NULL, y = "%") +
  scale_y_continuous(labels = scales::percent)

template_dataset("b3-indexes-current-portfolio") |>
  filter(index == "SMLL") |>
  collect() |>
  mutate(
    sector = str_extract(segment, "^[^/]+") |> str_trim(), # Extrai o texto antes do "/"
    subsector = str_extract(segment, "(?<=/ ).*") |> str_trim(), # Extrai o texto após o "/"
    sector = sector |>
      str_to_lower() |> # Converte para minúsculas
      stringi::stri_trans_general("Latin-ASCII") |> # Remove acentos
      str_replace_all("\\s+", " ") |> # Remove espaços extras
      str_trim() |> # Remove espaços no início e no fim
      str_replace_all("indls|industriais", "industriais") |> # Corrige inconsistências
      str_replace_all("cons n basico|cons n básico", "consumo não básico") |> # Unifica nomes
      str_replace_all("cons n ciclico|cons n cíclico", "consumo não cíclico") |> # Unifica nomes
      str_replace_all("consumo cíclico", "consumo cíclico") |> # Corrige inconsistências
      str_replace_all("financ e outros|financeiro e outros", "financeiro e outros") |> # Unifica nomes
      str_replace_all("utilidade públ", "utilidade pública") # Corrige inconsistências
  ) |>
  group_by(sector) |>
  summarise(asset_part = sum(asset_part)) |>
  ggplot(aes(x = reorder(sector, asset_part), y = asset_part)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = NULL, y = "%") +
  scale_y_continuous(labels = scales::percent)


df <- index_by_segment_get("SMLL")
df |>
  distinct(segment, segment_weight) |>
  ggplot(aes(x = reorder(segment, segment_weight), y = segment_weight)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = NULL, y = "%") +
  scale_y_continuous(labels = scales::percent)
