#' mod_visnet UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_visnet_ui = function(id, ...) {
  # useShinyjs must be called in app!
  ns = NS(id)
  tagList(
    shinyjs::inlineCSS(list(".noclick" = "pointer-events:none")),
    visNetworkOutput(ns("network"), ...)
  )
}
