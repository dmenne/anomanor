Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())


test_that("File without missing channels is read in correctly", {
  file = "test1.txt"
  cache_file = cache_file_name(file, time_zoom = 1)
  unlink(cache_file)
  mk = record_cache(file, 100, time_zoom = 1)

  expect_false(is.null(mk))
  checkmate::expect_file_exists(mk$png_hrm_file)
  checkmate::expect_file_exists(mk$png_line_file)
  checkmate::expect_file_exists(mk$cache_file)
  unlink(mk$png_hrm_file)
  unlink(mk$png_line_file)
  unlink(mk$cache_file)
})

test_that("File with missing channels is correctly interpolated", {
  skip_on_ci()
  file = test_data_dir("testdeactivatedchannels.txt")
  cache_file = cache_file_name(basename(file), time_zoom = 1)
  unlink(cache_file)
  mk = record_cache(file, 100, time_zoom = 1)
  expect_false(is.null(mk))
  checkmate::expect_file_exists(mk$png_hrm_file)
  checkmate::expect_file_exists(mk$png_line_file)
  checkmate::expect_file_exists(mk$cache_file)
})


