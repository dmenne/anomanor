Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Can create history plot", {
  gg = plot_history()
  expect_equal(length(gg$labels),  7)
  expect_equal(names(gg$data), c('history_date','user','method','finalized','cnt'))
})

