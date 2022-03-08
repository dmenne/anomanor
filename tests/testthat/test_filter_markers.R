Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())


test_that("filter_markers returns sublist", {
  markers = structure(list(
    sec = c(0, 40.91, 52.26, 68.87, 92.07, 111.96, 213.25, 237.14, 248.19, 274.94),
    index = c(0L, 227L, 290L, 383L, 511L, 622L, 1185L, 1317L, 1379L, 1527L),
    annotation = c("begin", "Rest", "Squeeze 1", "Squeeze 2", "Long Squeeze", "Cough",
                   "Push 1", "Push 2", "Push 3", "RAIR"),
    show = c(1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L)),
    class = c("tbl_df", "tbl", "data.frame"),
    row.names = c(NA, -10L))
  ret = filter_markers(markers, "all")
  expect_equal(ret, markers)

  ret = filter_markers(markers, "rair")
  expect_equal(nrow(ret), 1)
  expect_equal(ret$annotation, "RAIR")

  ret = filter_markers(markers, "tone")
  expect_equal(ret$annotation, c("Rest", "Squeeze 1", "Squeeze 2", "Long Squeeze"))

  ret = filter_markers(markers, "blub")
  expect_equal(nrow(ret), 0)
})