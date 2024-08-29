#' Run anomanor app
#'
#' Start anomanor app
#' @export
run_app = function() {
  shinyApp(
    ui = app_ui,
    server = app_server,
    onStart = function(){
      globals() # assigns g to .GlobalEnv
      onStop(function() {
        ano_poolClose()
      })
    },
    options = list(
      host = "0.0.0.0",
      port = if (getenv_r_config_active() == "keycloak_production" ||
                 Sys.getenv("DOCKER_ANOMANOR_STANDALONE") == "TRUE")  3838 else 4848),
    enableBookmarking = NULL,
    uiPattern = "/"
  )
}


