Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("History record can be added", {
  dbExecute(g$pool, "DELETE FROM history")
  history = add_history_record()
  expect_equal(names(history),
    c('history_date','user','method','finalized','cnt'))
  nrows_0 = nrow(history)
  expect_gte(nrows_0, 4)
  expect_equal(unique(history$method), c("h", "l"))
  hist_date = unique(history$history_date)
  expect_equal(length(hist_date),1)

  history_1 = dbGetQuery(g$pool, "SELECT * FROM history")
  expect_equal(history, history_1)
  n_iter = simulate_backward_history(history)
  history_2 = dbGetQuery(g$pool, "SELECT * FROM history order by history_date")
  unique_dates_2 = unique(history_2$history_date)
  expect_equal(length(unique_dates_2), n_iter)
  latest_hist_date = latest_history_date()
  expect_equal(latest_hist_date, hist_date)
  expect_gt(difftime(latest_hist_date, first_history_date()), 20)
})




