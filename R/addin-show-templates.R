#' Show templates.
#'
#' @description `display_template` opens an [RStudio
#'   gadget](https://shiny.rstudio.com/articles/gadgets.html) and
#'   [addin](http://rstudio.github.io/rstudioaddins/) that allows users
#'   to view the available templates.
#'
#' @return Addin has no return
#' @examples
#' \dontrun{
#' show_templates()
#' }
#' @export
show_templates <- function() {
  ui <- miniUI::miniPage(
    miniUI::miniTitleBar("rb3 Templates"),
    miniUI::miniContentPanel(
      DT::dataTableOutput("tableOutput")
    )
  )

  server <- function(input, output, session) {
    output$tableOutput <- DT::renderDataTable({
      df <- MarketData$show_templates()
      DT::datatable(df,
        selection = "none",
        options = list(paging = FALSE)
      )
    })
  }

  app <- shiny::shinyApp(ui = ui, server = server)
  viewer <- shiny::dialogViewer("rb3 Templates", width = 1200, height = 900)

  shiny::runGadget(app, viewer = viewer, stopOnCancel = TRUE)
}
