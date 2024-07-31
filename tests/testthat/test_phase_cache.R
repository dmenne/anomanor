Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())


test_that("phase_cache creates required files", {

  png_glob = glue("{g$png_dir}/*.png")
  record_cache_glob = glue("{g$record_cache_dir}/*.rds")

  unlink(png_glob)
  unlink(record_cache_glob)
  expect_equal(length(Sys.glob(png_glob)), 0)
  expect_equal(length(Sys.glob(record_cache_glob)), 0)

  zoom = 1L
  png_phase_file = png_phase_file_name(
    active_begin = 0L, active_width = zoom*227L, file = "test1.txt",
    max_p = 100L, method = "h", phase_label = "begin", time_zoom = 1L,
    window_width = 1080)
  expect_equal(basename(png_phase_file), "bhhv_100_0_begin_227_1080_1.png")
  ret = phase_cache(active_begin = 0L, active_width = 227L, file = "test1.txt",
                    max_p = 100L, method = "h", phase_label = "begin", time_zoom = 1L,
                    window_width = 1080)
  expect_equal(ret, png_phase_file)
  expect_equal(basename(Sys.glob(record_cache_glob)), "test1_1.rds")

  # Zoom 4
  zoom = 4L
  png_phase_file = png_phase_file_name(
    active_begin = 0L, active_width = 4*227L, file = "test1.txt",
    max_p = 100L, method = "h", phase_label = "begin", time_zoom = zoom,
    window_width = 1080)
  ret = phase_cache(active_begin = 0L, active_width = 227L, file = "test1.txt",
                    max_p = 100L, method = "h", phase_label = "begin",
                    time_zoom = zoom, window_width = 1080)
  expect_equal(ret, png_phase_file)
  checkmate::expect_subset("test1_4.rds", basename(Sys.glob(record_cache_glob)))
})
