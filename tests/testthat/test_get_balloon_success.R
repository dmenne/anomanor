Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("balloon_extension is meaningful", {
  # balloon extension is recreated with globals, so we only test if the entriese are
  # reasonable
  bs = get_balloon_success(g$pool)
  expect_equal(names(bs), c('record', "success"))
  expect_gt(nrow(bs), 3)
  expect_false(any(str_detect(bs$record, "\\.md")))
  expect_equal(unique(bs$success), c(NA, 'yes', "no"))
})