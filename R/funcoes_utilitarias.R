# Funções utilitárias do projeto: parâmetros, diretórios e proveniência dos dados.

# Parâmetros do estudo (fonte: docs/proposta-v2.md §3.1). Ficam aqui, e não no
# 00_setup.R, porque as funções dependem deles: quem carrega as funções (scripts
# ou testes) recebe os parâmetros junto.
ANOS_ESTUDO <- 2022:2025
PREFIXO_UF_RJ <- "33"
EPSG_SIRGAS2000 <- 4674
SEMENTE <- 20260925
REGRA_CASO <- "R2_vigilancia"  # D-04, aceita pela autora em 2026-09-25 (ADR-0002)

#' Cria a árvore de diretórios de dados e resultados, se ainda não existir.
#' Idempotente: rodar duas vezes não muda nada.
criar_diretorios <- function() {
  pastas <- c(
    file.path("dados", c("brutos", "intermediarios", "processados", "externos")),
    file.path("resultados", c("tabelas", "mapas", "estatistica", "objetos"))
  )
  for (p in pastas) dir.create(p, recursive = TRUE, showWarnings = FALSE)
  invisible(pastas)
}

# ---------------------------------------------------------------------------
# Manifesto de proveniência (CS-003)
#
# Todo arquivo que vem de fora do projeto é registrado em dados/MANIFESTO.md com
# URL, data do download, tamanho e SHA-256. O manifesto é uma tabela Markdown
# escrita E relida por estas funções: legível por gente no GitHub e verificável
# por código. Não editar à mão.
# ---------------------------------------------------------------------------

MANIFESTO_PADRAO <- file.path("dados", "MANIFESTO.md")
COLUNAS_MANIFESTO <- c("arquivo", "url", "baixado_em", "bytes", "sha256",
                       "versao", "descricao")
VAZIO_MANIFESTO <- "—"

#' SHA-256 do conteúdo de um arquivo (64 caracteres hexadecimais).
sha256_arquivo <- function(caminho) {
  digest::digest(file = caminho, algo = "sha256")
}

#' Caminho relativo à pasta de trabalho, com barras "/" em qualquer sistema.
#' O manifesto só aceita arquivos dentro do projeto.
caminho_relativo <- function(caminho) {
  abs <- normalizePath(caminho, winslash = "/", mustWork = TRUE)
  raiz <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  prefixo <- paste0(raiz, "/")
  if (!startsWith(tolower(abs), tolower(prefixo))) {
    stop("Arquivo fora do projeto, não pode entrar no manifesto: ", abs, call. = FALSE)
  }
  substring(abs, nchar(prefixo) + 1)
}

manifesto_vazio <- function() {
  as.data.frame(
    setNames(replicate(length(COLUNAS_MANIFESTO), character(0), simplify = FALSE),
             COLUNAS_MANIFESTO),
    stringsAsFactors = FALSE
  )
}

#' Lê o manifesto como data.frame de texto. Arquivo inexistente = manifesto vazio.
ler_manifesto <- function(manifesto = MANIFESTO_PADRAO) {
  if (!file.exists(manifesto)) return(manifesto_vazio())
  linhas <- readLines(manifesto, encoding = "UTF-8", warn = FALSE)
  tabela <- grep("^\\|", linhas, value = TRUE)
  if (length(tabela) < 2) return(manifesto_vazio())

  celulas <- lapply(tabela, function(l) {
    miolo <- sub("^\\|(.*)\\|\\s*$", "\\1", l)
    trimws(strsplit(miolo, "|", fixed = TRUE)[[1]])
  })
  if (!identical(celulas[[1]], COLUNAS_MANIFESTO)) {
    stop("Cabeçalho inesperado em ", manifesto, ": ",
         paste(celulas[[1]], collapse = ", "), call. = FALSE)
  }
  corpo <- celulas[-(1:2)]  # descarta cabeçalho e linha separadora
  if (length(corpo) == 0) return(manifesto_vazio())
  if (any(lengths(corpo) != length(COLUNAS_MANIFESTO))) {
    stop("Linha malformada em ", manifesto, call. = FALSE)
  }
  df <- as.data.frame(do.call(rbind, corpo), stringsAsFactors = FALSE)
  names(df) <- COLUNAS_MANIFESTO
  df[] <- lapply(df, function(x) ifelse(x == VAZIO_MANIFESTO, NA_character_, x))
  df
}

#' Escreve o manifesto, ordenado por arquivo para o diff do git ficar estável.
escrever_manifesto <- function(df, manifesto = MANIFESTO_PADRAO) {
  valores <- unlist(df, use.names = FALSE)
  if (any(grepl("[|\n]", valores[!is.na(valores)]))) {
    stop("Campo com '|' ou quebra de linha não cabe na tabela do manifesto", call. = FALSE)
  }
  df <- df[order(df$arquivo), COLUNAS_MANIFESTO, drop = FALSE]
  celula <- function(x) ifelse(is.na(x) | x == "", VAZIO_MANIFESTO, x)
  corpo <- if (nrow(df) == 0) character(0) else
    vapply(seq_len(nrow(df)), function(i) {
      paste0("| ", paste(celula(unlist(df[i, ])), collapse = " | "), " |")
    }, character(1))

  texto <- c(
    "# Manifesto de proveniência dos dados",
    "",
    "Gerado por `registrar_fonte()` (R/funcoes_utilitarias.R). Não editar à mão:",
    "`verificar_manifesto()` relê esta tabela e recalcula o SHA-256 de cada arquivo.",
    "",
    paste0("| ", paste(COLUNAS_MANIFESTO, collapse = " | "), " |"),
    paste0("|", strrep("---|", length(COLUNAS_MANIFESTO))),
    corpo
  )
  dir.create(dirname(manifesto), recursive = TRUE, showWarnings = FALSE)
  con <- file(manifesto, open = "wb")  # "wb" evita CRLF no Windows
  on.exit(close(con))
  writeLines(enc2utf8(texto), con, sep = "\n", useBytes = TRUE)
  invisible(df)
}

#' Registra (ou confirma) um arquivo externo no manifesto.
#'
#' - Arquivo novo: acrescenta uma linha.
#' - Mesmo arquivo, mesmo hash: não faz nada (idempotente).
#' - Mesmo arquivo, hash diferente: ERRO, a menos que substituir = TRUE.
#'   É o caso do banco vivo de 2025: rebaixar muda o conteúdo, e isso precisa
#'   ser uma decisão explícita, não um acidente.
registrar_fonte <- function(caminho, url, descricao, versao = NA_character_,
                            baixado_em = Sys.time(), substituir = FALSE,
                            manifesto = MANIFESTO_PADRAO) {
  if (!file.exists(caminho)) stop("Arquivo não encontrado: ", caminho, call. = FALSE)
  arquivo <- caminho_relativo(caminho)
  hash <- sha256_arquivo(caminho)
  m <- ler_manifesto(manifesto)

  i <- which(m$arquivo == arquivo)
  if (length(i) == 1) {
    if (identical(m$sha256[i], hash)) {
      message("Já registrado com o mesmo SHA-256: ", arquivo)
      return(invisible(m[i, ]))
    }
    if (!substituir) {
      stop("O conteúdo de ", arquivo, " mudou desde o registro.\n",
           "  manifesto: ", m$sha256[i], "\n  arquivo:   ", hash, "\n",
           "Se o novo download é intencional, use substituir = TRUE.", call. = FALSE)
    }
    m <- m[-i, , drop = FALSE]
  }

  nova <- data.frame(
    arquivo = arquivo,
    url = url,
    baixado_em = format(baixado_em, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    bytes = format(file.size(caminho), scientific = FALSE),
    sha256 = hash,
    versao = versao,
    descricao = descricao,
    stringsAsFactors = FALSE
  )
  escrever_manifesto(rbind(m, nova), manifesto)
  invisible(nova)
}

#' Confere arquivos contra o manifesto. Para no primeiro problema.
#'
#' Sem `arquivos`: confere todas as linhas do manifesto E exige que todo
#' arquivo de dados/brutos/ esteja registrado. É a trava do invariante
#' "sem manifesto, nada em dados/brutos/ é lido".
#' Com `arquivos`: confere só esses (uso típico: antes de ler um bruto).
verificar_manifesto <- function(arquivos = NULL, manifesto = MANIFESTO_PADRAO,
                                pasta_brutos = file.path("dados", "brutos")) {
  m <- ler_manifesto(manifesto)

  if (is.null(arquivos)) {
    brutos <- list.files(pasta_brutos, recursive = TRUE, full.names = TRUE)
    brutos <- brutos[basename(brutos) != ".gitkeep"]
    fora <- setdiff(vapply(brutos, caminho_relativo, character(1)), m$arquivo)
    if (length(fora) > 0) {
      stop("Arquivos em ", pasta_brutos, " sem registro no manifesto: ",
           paste(fora, collapse = ", "), call. = FALSE)
    }
    alvo <- m$arquivo
  } else {
    alvo <- vapply(arquivos, function(a) {
      if (!file.exists(a)) stop("Arquivo não encontrado: ", a, call. = FALSE)
      caminho_relativo(a)
    }, character(1), USE.NAMES = FALSE)
  }

  for (a in alvo) {
    i <- which(m$arquivo == a)
    if (length(i) == 0) {
      stop("Arquivo sem registro no manifesto: ", a,
           ". Registre com registrar_fonte() antes de ler.", call. = FALSE)
    }
    if (!file.exists(a)) {
      stop("Arquivo do manifesto ausente no disco: ", a,
           ". Baixe de novo (", m$url[i], ").", call. = FALSE)
    }
    hash <- sha256_arquivo(a)
    if (!identical(hash, m$sha256[i])) {
      stop("SHA-256 divergente em ", a, "\n  manifesto: ", m$sha256[i],
           "\n  arquivo:   ", hash, call. = FALSE)
    }
  }
  invisible(alvo)
}

#' Baixa um arquivo e registra no manifesto, reaproveitando o que já existe.
#'
#' Se o destino já existe e confere com o manifesto, não baixa de novo (cache
#' por hash). Se existe mas diverge, para: alguém alterou o arquivo ou o
#' manifesto, e isso precisa ser investigado, não sobrescrito.
baixar_e_registrar <- function(url, destino, descricao, versao = NA_character_,
                               manifesto = MANIFESTO_PADRAO) {
  if (file.exists(destino)) {
    m <- ler_manifesto(manifesto)
    if (caminho_relativo(destino) %in% m$arquivo) {
      verificar_manifesto(destino, manifesto = manifesto)
      message("Em cache e conferido: ", destino)
      return(invisible(destino))
    }
  }
  baixar_arquivo(url, destino)
  registrar_fonte(destino, url = url, descricao = descricao, versao = versao,
                  manifesto = manifesto)
  invisible(destino)
}

#' Baixa `url` para `destino`, retomando de onde parou se cair no meio.
#'
#' O download vai para `<destino>.parcial` e só é renomeado no fim, então nunca
#' existe um `destino` pela metade. Se uma tentativa falha, os bytes já baixados
#' ficam no .parcial e a próxima tentativa (ou a próxima execução) pede ao
#' servidor só o resto, com o cabeçalho HTTP Range.
baixar_arquivo <- function(url, destino, tentativas = 3, espera_s = 5) {
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  parcial <- paste0(destino, ".parcial")

  for (t in seq_len(tentativas)) {
    ja <- if (file.exists(parcial)) file.size(parcial) else 0
    h <- curl::new_handle(failonerror = TRUE)
    if (ja > 0) curl::handle_setopt(h, resume_from_large = ja)

    con <- file(parcial, open = "ab")  # "a" = acrescenta ao fim; "b" = binário
    res <- tryCatch(
      curl::curl_fetch_stream(url, function(pedaco) writeBin(pedaco, con), handle = h),
      error = function(e) e
    )
    close(con)

    if (!inherits(res, "error")) {
      # Servidor que ignora o Range responde 200 com o arquivo inteiro, que foi
      # acrescentado depois dos bytes antigos: o resultado estaria corrompido.
      if (ja > 0 && identical(res$status_code, 200L)) {
        message("Servidor ignorou a retomada; recomeçando do zero: ", url)
        unlink(parcial)
        next
      }
      file.rename(parcial, destino)
      return(invisible(destino))
    }

    message(sprintf("Tentativa %d/%d falhou (%s). %s bytes preservados para retomar.",
                    t, tentativas, conditionMessage(res),
                    format(if (file.exists(parcial)) file.size(parcial) else 0,
                           big.mark = ".")))
    if (t < tentativas) Sys.sleep(espera_s)
  }
  stop("Download falhou após ", tentativas, " tentativas: ", url,
       "\nOs bytes baixados ficam em ", parcial, " e a próxima execução retoma.",
       call. = FALSE)
}

#' Semana epidemiológica do Ministério da Saúde a partir de uma data.
#'
#' Semanas vão de domingo a sábado. A semana 1 é a que tem mais dias em janeiro,
#' ou seja, a que contém o dia 4 de janeiro. Por isso alguns anos têm 53 semanas
#' (ex.: 53/2025 = 28/12/2025 a 03/01/2026, calendário oficial da SMS-Rio).
#' Devolve data.frame com ano_epi e semana_epi (inteiros; NA onde a data é NA).
semana_epidemiologica <- function(data) {
  data <- as.Date(data)
  domingo <- data - as.POSIXlt(data)$wday           # wday: 0 = domingo
  ano <- as.POSIXlt(domingo + 3)$year + 1900L       # a quarta-feira decide o ano
  jan4 <- as.Date(sprintf("%04d-01-04", ano))
  inicio_sem1 <- jan4 - as.POSIXlt(jan4)$wday
  data.frame(
    ano_epi = as.integer(ano),
    semana_epi = as.integer(as.numeric(domingo - inicio_sem1) %/% 7 + 1)
  )
}

#' Lê config/fontes.yml (URLs das fontes ficam fora do código, trilha §6).
ler_fontes <- function(arquivo = file.path("config", "fontes.yml")) {
  yaml::read_yaml(arquivo)
}

# ---------------------------------------------------------------------------
# Execução do pipeline (CS-023)
# ---------------------------------------------------------------------------

# Saídas regeneráveis. Brutos e externos NÃO entram: são cache conferido pelo manifesto.
PASTAS_DERIVADAS <- c(
  file.path("dados", c("intermediarios", "processados")),
  file.path("resultados", c("tabelas", "mapas", "estatistica", "objetos"))
)

#' Apaga tudo o que o pipeline gera, preservando os .gitkeep. Usado por
#' `Rscript run.R --limpar` para provar que o pipeline refaz tudo do zero.
limpar_derivados <- function(pastas = PASTAS_DERIVADAS) {
  apagados <- 0L
  for (p in pastas[dir.exists(pastas)]) {
    alvo <- list.files(p, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
    alvo <- alvo[basename(alvo) != ".gitkeep" & !dir.exists(alvo)]
    apagados <- apagados + sum(file.remove(alvo))
    subpastas <- list.dirs(p, recursive = TRUE, full.names = TRUE)[-1]
    unlink(rev(subpastas), recursive = TRUE)
  }
  invisible(apagados)
}

#' Roda cada etapa num ambiente próprio (uma etapa não enxerga as variáveis da
#' outra), mede o tempo e para na primeira falha. Grava o log mesmo quando falha.
#' `etapas` é uma lista nomeada de funções sem argumento.
executar_etapas <- function(etapas, arquivo_log = file.path("resultados", "execucao.log")) {
  log <- data.frame(etapa = character(0), segundos = numeric(0), status = character(0),
                    stringsAsFactors = FALSE)
  gravar_log <- function() {
    dir.create(dirname(arquivo_log), recursive = TRUE, showWarnings = FALSE)
    linhas <- c(sprintf("Execução do pipeline em %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
                sprintf("%-22s %9s  %s", "etapa", "segundos", "status"),
                sprintf("%-22s %9.1f  %s", log$etapa, log$segundos, log$status),
                sprintf("%-22s %9.1f", "TOTAL", sum(log$segundos)))
    writeLines(linhas, arquivo_log, useBytes = TRUE)
  }
  for (nome in names(etapas)) {
    message("==> ", nome)
    t0 <- Sys.time()
    erro <- tryCatch({ etapas[[nome]](); NULL }, error = function(e) e)
    seg <- as.numeric(Sys.time() - t0, units = "secs")
    log[nrow(log) + 1, ] <- list(nome, seg, if (is.null(erro)) "ok" else paste("ERRO:", conditionMessage(erro)))
    if (!is.null(erro)) {
      gravar_log()
      stop("Pipeline parou em ", nome, ": ", conditionMessage(erro), call. = FALSE)
    }
  }
  gravar_log()
  invisible(log)
}

#' Etapa de script: roda o arquivo num ambiente novo, filho do global.
etapa_script <- function(arquivo) {
  force(arquivo)
  function() source(arquivo, local = new.env(parent = globalenv()), encoding = "UTF-8")
}

#' Etapa do relatório: chama o Quarto apontando para este R (QUARTO_R).
etapa_relatorio <- function(qmd = "08_relatorio.qmd") {
  force(qmd)
  function() {
    quarto <- Sys.which("quarto")
    if (!nzchar(quarto)) quarto <- "C:/Program Files/Quarto/bin/quarto.exe"
    if (!file.exists(quarto)) stop("Quarto não encontrado; instale-o ou rode sem o relatório (--sem-relatorio)")
    # No Windows, system2(env = ...) NÃO define variável: cola o texto antes do
    # comando (erro encontrado no CS-023). with_envvar define só durante a chamada.
    saida <- withr::with_envvar(
      c(QUARTO_R = normalizePath(R.home("bin"), winslash = "/")),
      suppressWarnings(system2(quarto, c("render", qmd), stdout = TRUE, stderr = TRUE))
    )
    status <- attr(saida, "status")
    if (!is.null(status) && status != 0) stop(paste(utils::tail(saida, 5), collapse = "\n"))
  }
}

# ---------------------------------------------------------------------------
# Exportação para planilha (CS-020)
# ---------------------------------------------------------------------------

#' Grava uma tabela para o Excel em português: UTF-8 com BOM (sem ele o Excel
#' lê os acentos como Latin-1 e "Niterói" vira "NiterÃ³i"), ";" como separador
#' e "," como decimal (o padrão do Excel com idioma pt-BR).
salvar_resultado <- function(df, nome, pasta = file.path("resultados", "tabelas", "exportacao")) {
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  caminho <- file.path(pasta, paste0(nome, ".csv"))
  con <- file(caminho, open = "wb")
  on.exit(close(con))
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)  # BOM do UTF-8
  texto <- utils::capture.output(
    utils::write.table(df, sep = ";", dec = ",", row.names = FALSE, na = "", qmethod = "double",
                       fileEncoding = "")
  )
  writeLines(enc2utf8(texto), con, sep = "\r\n", useBytes = TRUE)  # CRLF: o que o Excel espera
  invisible(caminho)
}

#' Lê de volta um CSV gravado por salvar_resultado() (para testes e conferência).
ler_resultado <- function(caminho) {
  utils::read.table(caminho, sep = ";", dec = ",", header = TRUE, quote = "\"",
                    fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, na.strings = "",
                    colClasses = "character")
}

#' "Carimbo" da exportação: quando, de que versão dos dados e com que regras.
#' Vai num LEIA-ME ao lado dos CSV, para não poluir as planilhas.
escrever_carimbo <- function(pasta, linhas_extra = character(0)) {
  commit <- tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE, stderr = FALSE),
                     error = function(e) NA_character_, warning = function(w) NA_character_)
  m <- ler_manifesto()
  bancos <- m[grepl("^dados/brutos/INFLUD", m$arquivo), c("arquivo", "versao")]
  texto <- c(
    "Tabelas exportadas pelo pipeline Cartografia & Saúde (SRAG-RJ 2022-2025).",
    paste("Gerado em:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("Commit do código:", if (length(commit) == 1 && !is.na(commit)) commit else "desconhecido"),
    paste("Critério de caso:", REGRA_CASO, "(ADR-0002)"),
    "Bancos SIVEP-Gripe (versão):",
    paste0("  ", bancos$arquivo, " (", bancos$versao, ")"),
    "Formato: UTF-8 com BOM, separador ';', decimal ','.",
    linhas_extra
  )
  caminho <- file.path(pasta, "LEIA-ME.txt")
  con <- file(caminho, open = "wb"); on.exit(close(con))
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
  writeLines(enc2utf8(texto), con, sep = "\r\n", useBytes = TRUE)
  invisible(caminho)
}
