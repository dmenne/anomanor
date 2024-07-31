Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())


test_that("get_line_xy returns vertical and horizontal cross sections", {
  cf = record_cache("test1.txt", 100, 1)$cache_file
  expect_true(file.exists(cf))
  dt = readRDS(cf)$data

  xy = get_line_xy(dt, start_time = 0, time_step = 0.18, time_zoom = 1,
      view = 1, x1 = 43, x2 = 268, y1 = 334, y2 = 334)
  expect_equal(dim(xy), c(225,4))
  expect_equal(names(xy), c("time", "pos", "press", "where"))
  expect_equal(attr(xy, "balloon_press"), 16.1)
  expect_equal(length(unique(xy$pos)), 1)

  # Test swapping
  xy_swap = get_line_xy(dt, start_time = 0, time_step = 0.18, time_zoom = 1,
                 view = 1, x1 = 268, x2 = 43, y1 = 334, y2 = 334)
  expect_equal(xy, xy_swap)


  xy = get_line_xy(dt, start_time = 0, time_step = 0.18, time_zoom = 1,
                   view = 1, x1 = 43, x2 = 43, y1 = 50, y2 = 100)
  expect_equal(length(unique(xy$time)), 1)
  expect_equal(dim(xy), c(21,4))

  # Test swapping
  xy_swap = get_line_xy(dt, start_time = 0, time_step = 0.18, time_zoom = 1,
                        view = 1, x1 = 43, x2 = 43, y1 = 100, y2 = 50)
  expect_equal(xy, xy_swap)

  # Test overflow
  xy = get_line_xy(dt, start_time = 0, time_step = 0.18, time_zoom = 1,
                   view = 1, x1 = 10000, x2 = 11200, y1 = 334, y2 = 334)
  expect_null(xy)
})
