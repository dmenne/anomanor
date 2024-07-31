Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("File with subsampling is correctly time-interpolated", {
  file = test_data_dir("test2.txt")
  cache_file = cache_file_name(basename(file), time_zoom = 1)
  unlink(cache_file)
  mk = record_cache(file, 100, time_zoom = 1)
  expect_false(is.null(mk))
  checkmate::expect_file_exists(mk$cache_file)

  checkmate::expect_file_exists(mk$png_hrm_file)
  checkmate::expect_file_exists(mk$png_line_file)
  checkmate::expect_file_exists(mk$cache_file)
  png_size = dim(png::readPNG(mk$png_hrm_file))
  expect_equal(png_size[1:2], c(g$image_height, 2736))

  png_size = dim(png::readPNG(mk$png_line_file))
  expect_equal(png_size[1:2], c(g$image_height, 2736))

  # Cleanup
  unlink(mk$png_hrm_file)
  unlink(mk$png_line_file)
  unlink(mk$cache_file)
  q = glue_sql("DELETE from record where record = 'test2'", .con = g$pool)
  dbExecute(g$pool, q)
})


test_that("File without subsampling is not interpolated", {
  file = test_data_dir("testnointerpolation.txt")
  cache_file = cache_file_name(basename(file), time_zoom = 1)
  unlink(cache_file)
  mk = record_cache(file, 100, time_zoom = 1)
  checkmate::expect_file_exists(mk$cache_file)

  checkmate::expect_file_exists(mk$png_hrm_file)
  png_size = dim(png::readPNG(mk$png_hrm_file))
  expect_equal(png_size[1:2], c(g$image_height, 1639))

  checkmate::expect_file_exists(mk$png_line_file)
  png_size = dim(png::readPNG(mk$png_line_file))
  expect_equal(png_size[1:2], c(g$image_height, 1639))

  # Cleanup
  unlink(mk$png_file)
  unlink(mk$cache_file)
  q = glue_sql("DELETE from record where record = 'testnointerpolation'", .con = g$pool)
  dbExecute(g$pool, q)
})
