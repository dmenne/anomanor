Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())
library(shiny)

test_that("Can call functions of mod_data_server", {
  args = list(
    app_user = "x_dora",
    max_p = reactive(100),
    time_zoom = reactive(2),
    rvalues = reactiveValues( # Not all required
      classification = 0,
      can_save = FALSE,
      can_classify = FALSE, # set by mod_data_server
      cancelled = FALSE,
      finalized = FALSE,
      section_pars = NULL,
      section_line = NULL, # from database
      request_draw_section = 0L,
      window_width = 500)
  )
  shiny::testServer(mod_data_server, args = args, expr = {

    returned =   session$getReturned()

    session$setInputs(classification_method =  TRUE)
    expect_equal(classification_method(), "l")
    session$setInputs(classification_method =  FALSE)
    expect_equal(classification_method(), "h")

    rec = records()
    expect_equal(rec$record, c("test1", "test2"))

    session$setInputs(record = "test1.txt")
    dt = data()
    expect_equal(names(dt), c("data", "time", "time_step"))
    expect_equal(length(dim(dt$data)), 2)
    expect_equal(dim(dt$data)[1], length(dt$time)[1])
    expect_equal(length(dt$time_step), 1)

    session$setInputs(record = "test2.txt")
    dt2 = data()
    expect_false(all(dim(dt2$data) ==  dim(dt$data)))

    session$setInputs(classification_phase = "RAIR")

    mk2 = markers_for_record("test2")
    expect_equal(nrow(mk2), 18)
    expect_equal(names(mk2), c("sec", "index", "annotation", "show"))

    mk = all_markers()
    checkmate::expect_data_frame(mk)
    expect_equal(names(mk), c("sec", "index", "annotation", "show"))

    session$setInputs(protocol_phase_start = 200)
    st =  start_time()
    session$setInputs(protocol_phase_start = 300)
    expect_equal(start_time() - st, args$time_zoom() * 100)

    # Simulate action buttons
    session$setInputs(classification_phase = "tone")
    session$setInputs(protocol_phase_start = 568 )
    session$setInputs(forward = 1)
    session$setInputs(back = 1)
  })
})
