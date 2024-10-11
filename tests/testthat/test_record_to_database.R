Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Examples and classifications are not overwritten", {
  file = "test1.txt"
  markers = tibble::tribble(
    ~sec, ~index, ~annotation,
    1, 1, "Squeeze",
    2, 2, "RAIR"
  )
  time_step = 0.15
  n_classifications_1 = n_classifications()
  record = file_path_sans_ext(file)
  sql_markers = glue_sql(
    "SELECT COUNT() as n_markers from marker where record = {record}",
    .con = g$pool)
  n_markers_before = as.integer(dbGetQuery(g$pool, sql_markers))
  expect_gt(n_markers_before, 2)

  # Write with new markers
  record_to_database(file, markers, time_step)
  n_classifications_2 = n_classifications()
  expect_equal(n_classifications_1, n_classifications_2)
  # check if time_step was updated, others should be same
  sql = "SELECT timestep from record where record = 'test1'"
  expect_equal(as.numeric(dbGetQuery(g$pool, sql)), time_step)
  n_markers_after = as.integer(dbGetQuery(g$pool, sql_markers))
  expect_equal(n_markers_after, 2)

  # Now make test1 example
  rep_sql = glue_sql(
    "UPDATE record SET anon_h = '$ex1', anon_l = '$ex1'",
    "where record = 'test1'", .con = g$pool)
  expect_equal(dbExecute(g$pool, rep_sql), 1)

  # test examples should not be touched
  new_time_step = 0.10
  record_to_database(file, markers, new_time_step)
  test1_rec = dbGetQuery(g$pool,
    "SELECT anon_h, anon_l, timestep from record where record='test1'")
  expect_equal(test1_rec$anon_h, '$ex1')
  expect_equal(test1_rec$anon_l, '$ex1')
  expect_equal(test1_rec$timestep, time_step)
  n_classifications_3 = n_classifications()
  expect_equal(n_classifications_1, n_classifications_3)
})


