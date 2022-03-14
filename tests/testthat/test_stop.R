Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

test_that("expect_error works on gi actions", {
  expect_error(stop("Hallo", call. = FALSE), "Hallo")
})

