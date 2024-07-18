Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

expect_names = c("valid_markers", "missing", "unexpected",
                 "duplicates", "unused_markers", "invalid_channels")

test_that("Duplicate squeeze returns message", {
  file = test_data_dir("testduplicatesqueeze.txt")
  ret = check_valid_record(file)
  checkmate::expect_list(ret)
  expect_equal(names(ret), expect_names)
  expect_equal(ret$duplicates[1], "Squeeze 2")
  expect_null(ret$missing)
  expect_null(ret$unexpected)
})

test_that("Valid file returns list with empty entries", {
  file = test_data_dir("test1.txt")
  ret = check_valid_record(file)
  checkmate::expect_list(ret)
  expect_equal(names(ret), expect_names)
  expect_equal(length(ret$missing), 0)
  expect_equal(length(ret$unexpected), 0)
  expect_gt(length(ret$unused_markers), 5)
})

test_that("Bad markers file returns unexpected and missing", {
  file = test_data_dir("testbadmarkers.txt")
  ret = check_valid_record(file)
  checkmate::expect_list(ret)
  expect_equal(names(ret), expect_names)
  expect_equal(ret$unexpected[1], "Blub")
  expect_setequal(ret$missing, c("Push 1", "Squeeze 1", "Squeeze 2"))
})


test_that("File with missing markers returns unexpected and missing", {
  file = test_data_dir("testmissingmarkers.txt")
  ret = check_valid_record(file)
  checkmate::expect_list(ret)
  expect_equal(names(ret), expect_names)
  expect_null(ret$unexpected)
  expect_setequal(ret$missing, c("Squeeze 2", "Push 1", "Push 2"))
})

test_that("File with empty markers but Annotation returns missing", {
  file = test_data_dir("testemptymarkers.txt")
  ret = check_valid_record(file)
  expect_setequal(ret$missing, c("Squeeze 1", "Squeeze 2", "Push 1", "Push 2", "RAIR"))
})


test_that("File without Annotation returns error", {
  file = test_data_dir("testnomarkers.txt")
  ret = check_valid_record(file)
  expect_match(ret, "No markers found in file")
})

test_that("Short file returns error", {
  file = test_data_dir("testshort.txt")
  ret = check_valid_record(file)
  expect_match(ret, "Only 19 rows")
})

