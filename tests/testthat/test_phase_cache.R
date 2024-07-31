Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())


test_that("phase_cache creates required files", {

  unlink(glue("{g$png_dir}/*.*"))
  unlink(glue("{g$record_cache_dir}/*.*"))
  expect_equal(length(dir(g$png_dir)), 0)
  expect_equal(length(dir(g$record_cache_dir)), 0)

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
  expect_equal(dir(g$record_cache_dir), "test1_1.rds")

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
  checkmate::expect_subset("test1_4.rds", dir(g$record_cache_dir))
})
