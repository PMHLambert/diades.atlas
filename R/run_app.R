#' Run the Shiny Application
#'
#' @param species_list list of species to use in the app
#' @inheritParams shiny::shinyApp
#' @param dataCatchment,catchment_geom,dataALL,ices_geom  internal datasets
#' 
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
#' @importFrom zeallot %<-%
#' 
run_app <- function(
  onStart = NULL,
  options = list(), 
  enableBookmarking = NULL,
  species_list = c(),
  dataCatchment = dataCatchment, 
  catchment_geom = catchment_geom, 
  dataALL = dataALL, 
  ices_geom = ices_geom
) {
  cli::cat_rule("run_app")
  
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options, 
      enableBookmarking = enableBookmarking
    ), 
    golem_opts = list(
      species_list = species_list,
      dataCatchment = dataCatchment, 
      catchment_geom = catchment_geom, 
      dataALL = dataALL, 
      ices_geom = ices_geom
    )
  )
}
