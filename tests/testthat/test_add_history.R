Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Can add history", {
  dbExecute(g$pool, "DELETE FROM history")
  first_added  = add_history_record_if_required()
  expect_equal(first_added, -1)
  later_added = add_history_record_if_required()
  expect_equal(later_added, 0)
  later_added = add_history_record_if_required(-1) # force
  # Will run into exception because of UNIQUE constraint that is skipped
  expect_equal(later_added, 0)
})



