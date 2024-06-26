# No setup needed

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

# These test fail on github actions by crashing the system
# without error message
test_that("parse_markers handles raises error without #", {
  hr_lines = c("Annotations:", "\t40.00\thusten")
  expect_error(parse_markers(hr_lines), "No valid")
})

test_that("parse_markers errors on empty annotation", {
  expect_error(parse_markers(""), "no annotations")
})


test_that("parse_markers errors on invalid", {
  hr_lines = c("Annotations:", "\t-1.0  #B7",
               "\t-1.0  #13", "20.00 husten", "40.00\t # Rest")
  expect_error(parse_markers(hr_lines), "Invalid channel")
})


test_that("parse_markers handles missing channels", {
  hr_lines = c("Annotations:", "\t-1.0  # B1",
               "\t-1.0  #B2", "20.00 husten", "40.00\t # Rest")
  pm = parse_markers(hr_lines)
  expect_equal(2,2)
  expect_equal(pm$invalid_channels, c("B1", "B2"))
  expect_equal(pm$markers$sec, c(0, 40))
  expect_equal(pm$markers$annotation,  c("begin", "Rest"))
  expect_equal(nrow(pm$unused_markers), 1)
  expect_equal(pm$unused_markers$sec, 20)
  expect_equal(pm$unused_markers$annotation, "husten")
})
