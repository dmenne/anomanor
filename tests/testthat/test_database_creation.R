Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
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

