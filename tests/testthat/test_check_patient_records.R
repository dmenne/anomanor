Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("Empty string on patient/record match", {
  ret = check_patient_records()
  expect_equal(ret, "")
})

test_that("Message on missing patient record", {
  from = file.path(g$patients_dir, "test1.md")
  to = file.path(g$patients_dir, "test1.mdxxx")
  # Next line: just in case deferred rename had not worked
  suppressWarnings(file.rename(to, from))
  expect_true(file.exists(from))
  file.rename(from, to)
  withr::defer(file.rename(to, from))
  expect_match(check_patient_records(), "without patient")
})

test_that("Message on missing anal manometry", {
  from = file.path(g$record_dir, "test1.txt")
  to = file.path(g$record_dir, "test1.txtxxx")
  # Next line: just in case deferred rename had not worked
  suppressWarnings(file.rename(to, from))
  expect_true(file.exists(from))
  file.rename(from, to)
  withr::defer(file.rename(to, from))
  expect_match(check_patient_records(), "without record")
})

