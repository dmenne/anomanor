Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

test_that("trivial test", {
  expect_error(stop("Hallo", call. = FALSE), "Hallo")
})

