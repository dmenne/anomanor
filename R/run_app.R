#' Run the Shiny Application
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @export
run_app = function(
  onStart = function(){
    g <<- globals() # g is defined in globals.R
    onStop(function() {
      ano_poolClose()
    })
  },
  options = list(
    host = "0.0.0.0",
    port = if (Sys.getenv("R_CONFIG_ACTIVE") == "keycloak_production" ||
               Sys.getenv("DOCKER_ANOMANOR_STANDALONE") == "TRUE")  3838 else NULL),
  enableBookmarking = NULL,
  uiPattern = "/",
  ...
) {
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}

