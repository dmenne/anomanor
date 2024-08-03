Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Can get and increment finalize count for existing user", {
  user = "aaron" # existing user
  cnt = get_finalize_count(user)
  expect_equal(cnt, 0)
  cnt = increment_finalize_count(user, cnt)
  expect_equal(cnt, 1)
  cnt = increment_finalize_count(user, cnt)
  expect_equal(cnt, 2)
})

test_that("Increment non-existing user returns NA", {
  user = "doesnotexist"
  cnt = get_finalize_count(user)
  expect_equal(cnt, 0L) # Maybe this should better fail
  cnt = increment_finalize_count(user, cnt)
  expect_equal(cnt, NA)
})
