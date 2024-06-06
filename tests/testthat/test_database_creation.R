Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

test_that("marker_classification_phase table exists and has values", {
  q = "SELECT * from marker_classification_phase "
  ret = dbGetQuery(g$pool, q)
  expect_setequal(ret$classification_phase, c("coord", "rair", "tone", NA))
  expect_setequal(ret$mtype, c("o", "n", "r"))
})


test_that("New sqlite database is created",{
  q = "SELECT DISTINCT user from classification"
  ret = dbGetQuery(g$pool, q)$user
  checkmate::expect_set_equal(ret, c(g$test_users, "x_consensus"))
  testthat::expect_true(file.exists(g$sqlite_path))
  expect_setequal(dir(g$record_cache_dir),
               c("test1_1.rds", "test2_1.rds"))
  expect_files = c("bhhv_100_1.png", "fdvt_100_1.png", "nse9_100_1.png",
      "scale_fdvt_100_1.png", "scale_nse9_100_1.png", "ymrt_100_1.png",
      "scale_100_h.png")
  expect_setequal(dir(g$png_dir), expect_files)
})


test_that("Database is recreated when a table is missing",{
  q = "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
  available_tables = dbGetQuery(g$pool, q)$name
  dbExecute(g$pool, "DROP TABLE ano_logs")
  available_after_drop_tables = dbGetQuery(g$pool, q)$name
  expect_output({
    g$pool = create_tables_and_pool(g$sqlite_path, g$record_cache_dir)},
    "incomplete")
  available_new_tables = dbGetQuery(g$pool, q)$name
  expect_equal(available_tables, available_new_tables)
})

# Creates warnings
# <pool> Checked-out object deleted before being returned.
# <pool> Make sure to `poolReturn()` all objects retrieved with `poolCheckout().`



