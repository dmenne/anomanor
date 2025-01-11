#' mod_visnet Server Functions
#'
#' @noRd
mod_visnet_server = function(id, vis_nodes, vis_edges,
                             classification_phase, finalized) {
stopifnot(
  is.data.frame(vis_nodes),
  is.data.frame(vis_edges),
  is.reactive(classification_phase),
  is.reactive(finalized)
)
moduleServer(
  id,
  function(input, output, session) {
    ns = NS(id)
    ns_network = ns("network")
    click_event = glue::glue("function(nodes){{Shiny.setInputValue(",
      "'{ns('vis_click')}', nodes.nodes[0], {{priority: 'event'}});}}")

    vis_def = reactive({
      nodes = vis_nodes %>%
        dplyr::filter(phase == classification_phase())
      edges = vis_edges %>%
        dplyr::filter(phase == classification_phase())
      visNetwork(nodes, edges) %>%
        visInteraction(
          dragNodes = FALSE,
          dragView = FALSE,
          zoomView = FALSE,
          selectable = TRUE
        ) %>%
        visEdges(
          arrows = list(
            to = list(enabled = TRUE, scaleFactor = 0.3)),
          shadow = TRUE,
          width =  1,
          font = list(size = 18)) %>%
        visOptions(
          autoResize = TRUE,
          highlightNearest = list(
            algorithm = "hierarchical",
            hover = TRUE,
            labelOnly = TRUE,
            enabled = FALSE,
            degree = 3,
            hideColor = "rgba(20, 20, 20, 0.1)"
          )
        ) %>%
        visPhysics(enabled = FALSE) %>%
        # https://stackoverflow.com/a/43345078/229794
        visNodes(
          shape = "box",
          widthConstraint = 180,
          heightConstraint = 50,
          borderWidth = 1,
          borderWidthSelected = 3,
          shapeProperties = list(borderRadius = 5),
          margin = 5,
          # 5 Default
          font = list(size = 16),
          shadow = TRUE
        )  %>%
        visEvents(
          click = click_event
        )
    })

    output$network = renderVisNetwork({
      vis_def()
    })

    # Disable buttons if finalized
    observe({
      js = ifelse(finalized(),
        glue::glue("$('#{ns_network}').addClass('noclick')"),
        glue::glue("$('#{ns_network}').removeClass('noclick')"))
      shinyjs::runjs(js)
    })

  })
}

