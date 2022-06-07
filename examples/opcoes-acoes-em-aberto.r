
library("httr")

res <- GET("https://www.b3.com.br/json/20220425/Posicoes/Empresa/SI_C_OPCPOSABEMP.json")

txt <- res |> content("text", encoding = "utf8")

jason_mtcars <- jsonlite::serializeJSON(mtcars)
l <- jsonlite::unserializeJSON(jason_mtcars)

l <- jsonlite::fromJSON(txt)

df <- do.call(rbind, l$Empresa)

f <- download_marketdata("OpcoesAcoesEmAberto",
  do_cache = FALSE, refdate = Sys.Date() - 1
)

df <- read_marketdata(f, "OpcoesAcoesEmAberto")

str(df)
head(df)