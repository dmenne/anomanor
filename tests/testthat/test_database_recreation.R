Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
#withr::defer(cleanup_test_data())

test_that("Database is recreated when a table is missing",{
  q = "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
  available_tables = dbGetQuery(g$pool, q)$name
  dbExecute(g$pool, "DROP TABLE ano_logs")
  available_after_drop_tables = dbGetQuery(g$pool, q)$name
  expect_equal(setdiff(available_tables, available_after_drop_tables), "ano_logs" )
  expect_output({
    g$pool = suppressWarnings(
      create_tables_and_pool(g$sqlite_path, g$record_cache_dir))},
    "Database incomplete")
  available_new_tables = dbGetQuery(g$pool, q)$name
  expect_equal(available_tables, available_new_tables)
})


