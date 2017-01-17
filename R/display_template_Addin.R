
display_template_Addin <- function() {

  classes_ <- MarketData$show_templates()[['Class Name']]
  ui <- miniUI::miniPage(
    miniUI::miniTitleBar("rbmfbovespa View Template"),
    miniUI::miniContentPanel(
      shiny::selectInput("templateClass", label = h3("Template Classes"),
                  choices = classes_,
                  selected = 1),
      shiny::hr(),
      shiny::uiOutput('templateOutput'),
      DT::dataTableOutput("tableOutput")
    )
  )


  server <- function(input, output, session) {

    output$templateOutput <- shiny::renderUI({
      tpl_ <- MarketData$retrieve_template(input$templateClass)
      shiny::tags$div(
        shiny::tags$p('Template ID: ', tpl_$id),
        shiny::tags$p('Filename: ', tpl_$filename),
        shiny::tags$p('File type: ', tpl_$file_type)
      )
    })

    output$tableOutput <- DT::renderDataTable({
      tpl_ <- MarketData$retrieve_template(input$templateClass)
      DT::datatable(as.data.frame(tpl_$fields),
                    selection = 'none',
                    options = list(paging = FALSE))
    })


  }

  app <- shinyApp(ui = ui, server = server)
  viewer <- dialogViewer("rbmfbovespa Show Templates", width = 1200, height = 900)
  runGadget(app, viewer = viewer, stopOnCancel = TRUE)

}
