Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())
tc = "testcommented"

# needs an installed touch utility (e.g.from rtools)
stopifnot(Sys.which('touch')  != "")

test_that("Database and cache are updated when a file is added", {
  source_tc = test_data_dir(glue("{tc}.txt"))
  dest_tc = file.path(g$record_dir, glue("{tc}.txt"))
  unlink(dest_tc)
  ctc = file.path(g$record_cache_dir, glue("{tc}_1.rds"))
  unlink(ctc) # In case it exists
  expect_false(file.exists(ctc))
  q = glue_sql("DELETE From record where record ={tc}", .con = g$pool)
  dbExecute(g$pool, q)

  file.copy(source_tc, g$record_dir)
  expect_true(file.exists(dest_tc))
  initial_record_cache()
  expect_equal(touch_offset(dest_tc, 200), 0)
  ft_new = as.integer(file.info(dest_tc)$mtime)

  initial_record_cache()
  q = glue_sql("SELECT file_mtime From record where record={tc}", .con = g$pool)
  ft_new_db = dbGetQuery(g$pool, q)$file_mtime
  expect_equal(as.integer(ft_new), ft_new_db)
  testthat::expect_true(file.exists(ctc))
})


test_that("png is recreated after simulated record overwrite", {
  # Setup
  rec = file.path(g$record_dir, "test1.txt")
  expect_true(file.exists(rec))

  cache0_file = file.path(g$record_cache_dir, "test1_1.rds")
  checkmate::expect_file_exists(cache0_file)
  cache0_mtime = file.info(cache0_file)$mtime

  png0_file = glue("{g$png_dir}/bhhv_100_1.png")
  checkmate::expect_file_exists(png0_file)
  png0_mtime = file.info(png0_file)$mtime

  # Action
  touch_offset(rec, 180)
  initial_record_cache()

  # Test
  cache1_mtime = file.info(cache0_file)$mtime
  expect_gt(cache1_mtime, cache0_mtime)

  png1_mtime = file.info(png0_file)$mtime
  expect_gt(png1_mtime, png0_mtime)
})

test_that("Cache files are created on initial_record_cache", {
  # Setup
  unlink(file.path(g$record_dir, glue("{tc}.txt")))
  unlink(dir(g$record_cache_dir, full.names = TRUE))
  dbExecute(g$pool,"PRAGMA foreign_keys=ON")
  dbExecute(g$pool, "DELETE from record")
  ret = dbGetQuery(g$pool, "SELECT record from record")
  expect_equal(nrow(ret), 0)

  # Action
  initial_record_cache()
  ret = dbGetQuery(g$pool, "SELECT record from record")
  # Test
  expect_equal(ret$record, c("test1", "test2"))
  expect_setequal(dir(g$record_cache_dir),
                  c("test1_1.rds", "test2_1.rds"))
})


