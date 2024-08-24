Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Can create history plot", {
  print(plot_history())
  expect_true(TRUE)
})

