Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())


test_that("get_app_user returns valid user", {
  expect_equal(Sys.getenv("SHINYPROXY_USERNAME"), "")
  expect_equal(get_app_user(), "test")
  Sys.setenv(SHINYPROXY_USERNAME = "super")
  expect_equal(get_app_user(), "super")
  Sys.setenv(SHINYPROXY_USERNAME = "random")
  ret = get_app_user()
  expect_type(ret, "character")
  expect_equal(nchar(ret), 7)
  Sys.setenv(SHINYPROXY_USERNAME = "")
  # app_groups
  expect_equal(get_app_groups(), "trainees")
})

test_that("ano_button is valid HTML", {
  ret = as.character(ano_bttn("test_button", "save", "primary"))
  expect_match(ret, "Test_button")
  expect_match(ret, 'id="test_button"')
  expect_match(ret, 'bttn-primary')
})


