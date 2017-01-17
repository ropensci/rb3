
show_templates_Addin <- function() {

  ui <- miniUI::miniPage(
    miniUI::miniTitleBar("rbmfbovespa Templates"),
    miniUI::miniContentPanel(
      DT::dataTableOutput("tableOutput")
    )
  )

  server <- function(input, output, session) {

    output$tableOutput <- DT::renderDataTable({
      DT::datatable(MarketData$show_templates(),
                    selection = 'none',
                    options = list(paging = FALSE))
    })

  }

  app <- shiny::shinyApp(ui = ui, server = server)
  viewer <- shiny::dialogViewer("rbmfbovespa Templates", width = 1200, height = 900)
  shiny::runGadget(app, viewer = viewer, stopOnCancel = TRUE)
}
