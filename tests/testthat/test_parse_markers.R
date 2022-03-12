Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

test_that("parse_markers handles regular tabs", {
  hr_lines = c("Annotations:", "\t40.00\t#Rest")
  pm = parse_markers(hr_lines)
  expect_null(pm$invalid_channels)
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 0)
})

test_that("parse_markers handles regular tabs with space", {
  hr_lines = c("Annotations:", "\t40.00\t# Rest")
  pm = parse_markers(hr_lines)
  expect_null(pm$invalid_channels)
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 0)
})


test_that("parse_markers handles regular tabs with spaces", {
  hr_lines = c("Annotations:", "\t40.00\t#  Rest")
  pm = parse_markers(hr_lines)
  expect_null(pm$invalid_channels)
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 0)
})

test_that("parse_markers handles multiple rows", {
  hr_lines = c("Annotations:", "\t20.00\thusten","\t40.00\t# Rest")
  pm = parse_markers(hr_lines)
  expect_null(pm$invalid_channels)
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 1)
  expect_equal(pm$unused_markers$sec, 20)
  expect_equal(pm$unused_markers$annotation, "husten")
})

test_that("parse_markers handles multiple rows with spaces", {
  hr_lines = c("Annotations:", "  20.00 husten","40.00\t # Rest")
  pm = parse_markers(hr_lines)
  expect_null(pm$invalid_channels)
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 1)
  expect_equal(pm$unused_markers$sec, 20)
  expect_equal(pm$unused_markers$annotation, "husten")
})

test_that("parse_markers handles multiple tabs", {
  hr_lines = c("Annotations:", "\t\t20.00\thusten","\t40.00\t# Rest")
  pm = parse_markers(hr_lines)
  expect_null(pm$invalid_channels)
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 1)
  expect_equal(pm$unused_markers$sec, 20)
  expect_equal(pm$unused_markers$annotation, "husten")
})

