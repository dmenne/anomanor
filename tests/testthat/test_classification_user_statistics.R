Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())
options(warn = 2)

test_that("classification_user_statistics returns valid data",{
  ret = classification_user_statistics()
  expect_setequal(ret$user, c(g$test_users, "x_consensus"))
  expect_equal(names(ret), c(
    'user','email','name','verified','group','method','saved','finalized' ))
  ut = user_datatable(ret)
  expect_s3_class(ut, c("datatables", "htmlwidget"))
  expect_equal(as_tibble(ut$x$data), ret)
})


test_that("classification_statistic returns valid data", {
  ret = classification_statistics_html(method = 'h')
  expect_equal(names(ret), c("rair", "tone", "coord"))
  expect_true(all(map_chr(ret, function(x) class(x) ) == "flextable"))
  rh = map(ret, function(x) htmltools_value(x, ft.align = "left") )
  expect_equal(names(rh), c("rair", "tone", "coord"))
  expect_true(class(rh) == "list")

  ret = classification_statistics_html(method = 'l')
  expect_equal(names(ret), c("rair", "tone", "coord"))
  expect_true(all(map_chr(ret, function(x) class(x) ) == "flextable"))
})

test_that("number_of_classification returns valid integer", {
  ret = number_of_classifications(g$test_users[1])
  expect_gt(ret, 1)
  expect_true(is.integer(ret))
  ret = number_of_classifications("boom")
  expect_equal(ret, 0)
})

# This must be last because data are deleted
test_that("classification returns null without data", {
  cu0 = classification_user_statistics()
  delete_record("test2", delete_classifications = TRUE)
  delete_record("test1", delete_classifications = FALSE)
  cu1 = classification_user_statistics()
  expect_equal(cu0[,1:6], cu1[,1:6])
  expect_equal(dir(g$png_dir), "scale_100_h.png")

  ret = classification_statistics_html(method = 'h')
  expect_equal(names(ret), c("rair", "tone", "coord"))
  expect_s3_class(ret$rair, "flextable")

  delete_record("test1", delete_classifications = TRUE)
  ret = classification_user_statistics()
  expect_true(all(map_lgl(ret, is.null)))
  expect_null(ret)
})
