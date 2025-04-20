# Script para ler a planilha "Setorial B3 10-03-2025 (português).xlsx"
# e criar dataframes conforme solicitado

# Carregar bibliotecas necessárias
library(readxl)
library(dplyr)
library(stringr)
library(tidyr)

# Definir o caminho do arquivo
file_path <- "examples/Setorial B3 10-03-2025 (português).xlsx"

# Verificar se o arquivo existe
if (!file.exists(file_path)) {
  stop("Arquivo não encontrado: ", file_path)
}

# Listar as sheets disponíveis na planilha
sheets <- excel_sheets(file_path)
print(paste("Sheets encontradas:", paste(sheets, collapse = ", ")))

# Ler e processar a planilha "Class_setorial"
# Esta planilha tem uma estrutura não-linear com cabeçalhos em diferentes linhas
process_class_setorial <- function() {
  # Ler todos os dados da planilha sem especificar cabeçalhos
  raw_data <- read_excel(
    file_path, 
    sheet = "Class_setorial",
    col_names = FALSE
  )
  
  # Localizar índices de linhas com os cabeçalhos
  header_rows <- which(raw_data[[1]] == "SETOR ECONÔMICO")
  subheader_rows <- which(raw_data[[4]] == "CÓDIGO LISTAGEM")
  
  if (length(header_rows) == 0 || length(subheader_rows) == 0) {
    warning("Não foi possível identificar os cabeçalhos na planilha 'Class_setorial'")
    return(NULL)
  }
  
  # Identificar as colunas de interesse
  header_row <- header_rows[1]
  subheader_row <- subheader_rows[1]
  
  # Construir os nomes das colunas a partir dos cabeçalhos identificados
  col_names <- character(5)
  col_names[1] <- "SETOR ECONÔMICO"
  col_names[2] <- "SUBSETOR"
  col_names[3] <- "SEGMENTO"
  col_names[4] <- "CÓDIGO LISTAGEM"
  col_names[5] <- "SEGMENTO LISTAGEM"
  
  # Identificar as posições das colunas no dataframe
  col_positions <- c(1, 2, 3, 4, 5)
  
  # Criar um novo dataframe apenas com os dados a partir da linha após os cabeçalhos
  start_row <- max(header_row, subheader_row, na.rm = TRUE) + 2
  data_rows <- raw_data[start_row:nrow(raw_data), col_positions]
  
  # Converter para tibble e definir os nomes das colunas
  df <- as_tibble(data_rows)
  colnames(df) <- col_names
  df$SEGMENTO2 <- NA
  df$SEGMENTO2[which(is.na(df$`CÓDIGO LISTAGEM`))] <- df$SEGMENTO[which(is.na(df$`CÓDIGO LISTAGEM`))]
  
  # Preencher valores de setor e subsetor para baixo
  df <- df %>%
    fill(`SETOR ECONÔMICO`, .direction = "down") %>%
    fill(SUBSETOR, .direction = "down") %>%
    fill(SEGMENTO, .direction = "down") |> 
    fill(SEGMENTO2, .direction = "down")

  # Remover linhas completamente vazias
  df <- df %>%
    filter(!if_all(`CÓDIGO LISTAGEM`, is.na))
  
  df <- df |>
    mutate(SEGMENTO = SEGMENTO2) |>
    select("SETOR ECONÔMICO", "SUBSETOR", "SEGMENTO", "CÓDIGO LISTAGEM", "SEGMENTO LISTAGEM")
  
  df <- df |> filter(`SETOR ECONÔMICO` != "SETOR ECONÔMICO")

  return(df)
}

# Ler e processar a planilha "Estrutura"
process_estrutura <- function() {
  # Ler todos os dados da planilha sem especificar cabeçalhos
  raw_data <- read_excel(
    file_path, 
    sheet = "Estrutura",
    col_names = TRUE
  )
  
  # Identificar os nomes corretos das colunas
  col_names <- c(
    "Cód Setor Econômico", "Setor Econômico", 
    "Cód Subsetor", "Subsetor", 
    "Cód Segmento", "Segmento", 
    "Cód Subsegmento", "Subsegmento"
  )
  
  # Verificar se os nomes das colunas já estão corretos
  existing_cols <- colnames(raw_data)
  need_rename <- !all(col_names %in% existing_cols)
  
  if (need_rename) {
    # Padrão de colunas esperado
    pattern_cols <- c(
      "Cód", "Setor Econômico", 
      "Cód", "Subsetor", 
      "Cód", "Segmento", 
      "Cód", "Subsegmento"
    )
    
    # Verificar se temos 8 colunas para renomear
    if (ncol(raw_data) == 8) {
      colnames(raw_data) <- col_names
    } else {
      warning("O número de colunas na planilha 'Estrutura' não é o esperado (8).")
      return(NULL)
    }
  }
  
  # Preencher valores vazios (NA) para formar a estrutura completa
  df <- raw_data %>%
    fill(`Setor Econômico`, .direction = "down") %>%
    fill(`Cód Setor Econômico`, .direction = "down") %>%
    fill(Subsetor, .direction = "down") %>%
    fill(`Cód Subsetor`, .direction = "down")
  
  # Remover linhas completamente vazias
  df <- df %>%
    filter(!if_all(everything(), is.na))
  
  return(df)
}

# Processar as planilhas
class_setorial <- process_class_setorial()
estrutura <- process_estrutura()

# Mostrar resultados
if (!is.null(class_setorial)) {
  print("Estrutura do dataframe 'class_setorial':")
  print(str(class_setorial))
  print("Primeiras linhas do dataframe 'class_setorial':")
  print(head(class_setorial))
} else {
  warning("Não foi possível criar o dataframe 'class_setorial'")
}

if (!is.null(estrutura)) {
  print("Estrutura do dataframe 'estrutura':")
  print(str(estrutura))
  print("Primeiras linhas do dataframe 'estrutura':")
  print(head(estrutura))
} else {
  warning("Não foi possível criar o dataframe 'estrutura'")
}

# Salvar os dataframes como objetos do ambiente global
assign("class_setorial", class_setorial, envir = .GlobalEnv)
assign("estrutura", estrutura, envir = .GlobalEnv)

# Mensagem final
print("Processamento concluído. Os dataframes 'class_setorial' e 'estrutura' foram criados.")