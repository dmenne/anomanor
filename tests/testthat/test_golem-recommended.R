Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())


test_that("app ui", {
  ui = app_ui()
  golem::expect_shinytaglist(ui)
  # Check that formals have not been removed
  fmls = formals(app_ui)
  for (i in c("request")) {
    expect_true(i %in% names(fmls))
  }
})

test_that("app server", {
  server = app_server
  expect_true(is.function(server))
  # Check that formals have not been removed
  fmls = formals(app_server)
  for (i in c("input", "output", "session")) {
    expect_true(i %in% names(fmls))
  }
})

