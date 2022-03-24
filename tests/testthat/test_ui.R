Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

# smoke tests for ui_s

test_that("app_ui returns valid structure", {
  app = app_ui()
  expect_type(app, "list")
  expect_equal(length(app), 2)
  expect_type(app[[1]], "list")
  expect_type(app[[2]], "list")
})

test_that("mod_admin_ui returns valid structure", {
  mod = mod_admin_ui("admin")
  expect_type(mod, "list")
  expect_equal(length(mod), 1)
  expect_s3_class(mod[[1]], "shiny.tag")
})

test_that("mod_data_ui returns valid structure", {
  mod = mod_data_ui("data")
  expect_type(mod, "list")
  expect_equal(length(mod), 12)
})

