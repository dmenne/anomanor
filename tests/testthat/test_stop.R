Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

test_that("expect_error works on gi actions", {
  a = try(stop("Hallo, welt", call. = FALSE))
  expect_s3_class(a, "try-error")
})

