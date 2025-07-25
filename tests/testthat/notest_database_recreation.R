Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Database is recreated when a table is missing",{
  q = "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
  available_tables = dbGetQuery(g$pool, q)$name
  # Creating new tables without deleted ano_logs should return current pool
  expect_output({
    g$pool = create_tables_and_pool(g$sqlite_path, g$record_cache_dir)
  }, "Using existing")

  dbExecute(g$pool, "DROP TABLE ano_logs")
  available_after_drop_tables = dbGetQuery(g$pool, q)$name
  expect_equal(setdiff(available_tables, available_after_drop_tables), "ano_logs" )
  new_pool = create_tables_and_pool(g$sqlite_path, g$record_cache_dir)
  available_new_tables = dbGetQuery(new_pool, q)$name
  expect_equal(available_tables, c(available_new_tables, "nodes","edges", "balloon_success"))
  pool::poolClose(new_pool)
})
