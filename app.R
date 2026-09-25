# app.R — painel Shiny + leaflet para a vigilância (CS-021)
#
# Lê só dados/processados/ e resultados/ (rode run.R antes). Filtros: agente,
# ano e camada (incidência suavizada ou agrupamentos LISA). Clique num município
# para ver casos, população, taxas e classe LISA.
#
# Uso, da raiz do projeto:  shiny::runApp()

for (arquivo in list.files("R", pattern = "^funcoes_.*\\.R$", full.names = TRUE)) {
  source(arquivo, encoding = "UTF-8", local = TRUE)
}

# Estado de erro: se o pipeline não rodou, o painel abre e explica o que falta.
base <- tryCatch(carregar_dados_painel(), error = function(e) e)

nota <- paste(
  "Taxa suavizada por Bayes empírico (ADR-0003, D-09). LISA: vizinhança Queen,",
  "correção FDR por mapa; cor cheia = confirmado, cor clara = indicativo;",
  "borda tracejada = município com um único vizinho (ADR-0004)."
)

ui <- bslib::page_sidebar(
  title = "SRAG no Estado do Rio de Janeiro — incidência e agrupamentos espaciais",
  theme = bslib::bs_theme(version = 5),
  shiny::useBusyIndicators(),
  sidebar = bslib::sidebar(
    width = 300,
    shiny::selectInput("agente", "Agente", choices = stats::setNames(AGENTES, ROTULOS_AGENTE[AGENTES])),
    shiny::selectInput("ano", "Ano epidemiológico", choices = rev(ANOS_ESTUDO)),
    shiny::radioButtons("camada", "Camada",
                        choices = c("Incidência (taxa suavizada)" = "incidencia",
                                    "Agrupamentos (Moran local)" = "lisa")),
    shiny::helpText(nota),
    shiny::uiOutput("resumo")
  ),
  bslib::card(
    full_screen = TRUE,
    bslib::card_header(shiny::textOutput("titulo_mapa", inline = TRUE)),
    leaflet::leafletOutput("mapa", height = "72vh")
  )
)

server <- function(input, output, session) {
  dados <- shiny::reactive({
    shiny::validate(shiny::need(!inherits(base, "error"),
                                if (inherits(base, "error")) conditionMessage(base) else ""))
    shiny::req(input$agente, input$ano)
    d <- dados_painel(base, input$agente, as.integer(input$ano))
    shiny::validate(shiny::need(nrow(d) > 0, "Sem dados para esta combinação de agente e ano."))
    d
  })

  output$titulo_mapa <- shiny::renderText({
    sprintf("%s — %s, %s", if (identical(input$camada, "lisa")) "Agrupamentos espaciais" else "Incidência",
            ROTULOS_AGENTE[[input$agente]], input$ano)
  })

  output$mapa <- leaflet::renderLeaflet(mapa_painel(dados(), input$camada))

  output$resumo <- shiny::renderUI({
    d <- dados()
    conf <- d$nome[d$nivel == "confirmado"]
    shiny::tagList(
      shiny::tags$hr(),
      shiny::tags$p(shiny::tags$b("Casos no estado: "),
                    formatC(sum(d$casos), format = "d", big.mark = ".")),
      shiny::tags$p(shiny::tags$b("Agrupamentos confirmados: "),
                    if (length(conf) == 0) "nenhum" else paste(sort(conf), collapse = ", ")),
      shiny::tags$p(shiny::tags$b("Indicativos (sem correção): "), sum(d$nivel == "indicativo"))
    )
  })
}

shiny::shinyApp(ui, server)
