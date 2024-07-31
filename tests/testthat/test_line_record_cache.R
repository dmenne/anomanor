# Tests without database
Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())


test_that("test_hook for record_cache is called when attached", {
  ss = NULL
  records_file = NULL
  min_p = 0
  max_p = 0
  time_step_stretched = .18

  test_hook = function(ss1, records_file1, min_p1, max_p1, time_step_stretched1){
    ss <<- ss1
    records_file <<- records_file1
    min_p <<- min_p1
    max_p <<- max_p1
    time_step_stretched <<- time_step_stretched1
  }

  file = file.path(g$record_dir, "test1.txt")
  checkmate::expect_file_exists(file)
  mr = record_cache(file, max_p = 100, time_zoom = 1, test_hook = test_hook)
  expect_equal(max_p, 100)
  checkmate::expect_list(mr)
  expect_equal(records_file, file)
  expect_equal(names(mr), c("png_hrm_file", "png_line_file", "cache_file"))
  expect_true(all(purrr::map_lgl(mr, file.exists)))
  checkmate::expect_file_exists(unlist(mr))
  expect_equal(time_step_stretched, .18)
})

