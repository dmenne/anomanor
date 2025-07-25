Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())
options(warn = 2)

test_that("classification_user_statistics returns valid data", {
  ret = classification_user_statistics()
  expect_setequal(ret$user, c(g$test_users, "x_consensus"))
  expect_equal(names(ret), c(
    "user", "email", "name", "verified", "group", "method", "saved", "finalized" ))
  ut = user_datatable(ret)
  expect_s3_class(ut, c("datatables", "htmlwidget"))
  expect_equal(as_tibble(ut$x$data), ret)
})


test_that("number_of_classification returns valid integer", {
  ret = number_of_classifications(g$test_users[1])
  expect_gt(ret, 1)
  expect_true(is.integer(ret))
  ret = number_of_classifications("boom")
  expect_equal(ret, 0)
})

