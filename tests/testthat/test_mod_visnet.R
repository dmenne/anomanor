Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
ano_pool_close() # Not used

test_that("Can create vis network", {
  args = list(
    vis_nodes = g$nodes, # global
    vis_edges = g$edges, # global
    classification_phase = reactive("rair"),
    finalized = reactive(0))

  shiny::testServer(mod_visnet_server, args = args,
    {
      v = vis_def()
      checkmate::expect_class(v, c("visNetwork", "htmlwidget"))
      expect_equal(length(v$x$nodes$label), 3)
      checkmate::expect_subset(v$x$nodes$label, g$nodes$label)
    }
  )
  args$classification_phase = reactive("blub")
  shiny::testServer(mod_visnet_server, args = args,
    {
      v = vis_def()
      checkmate::expect_class(v, c("visNetwork", "htmlwidget"))
      expect_equal(length(v$x$nodes$label), 0)
    }
  )
})
