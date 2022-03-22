

test_that("copy_from_test_data can handle multiple cases", {
  dest_dir = file.path(tempdir(), "patients")
  unlink(dest_dir, recursive = TRUE)
  ret = copy_from_data_store(dest_dir)
  expect_equal(ret, 2)

  unlink(file.path(dest_dir, "test1.md"))
  ret = copy_from_data_store(dest_dir, if_empty_only = FALSE)
  expect_equal(ret, 1)
  unlink(file.path(dest_dir, "test1.md"))
  ret = copy_from_data_store(dest_dir, if_empty_only = TRUE)
  expect_equal(ret, 0)

  unlink(file.path(dest_dir, "test1.md"))
  unlink(file.path(dest_dir, "test2.md"))
  ret = copy_from_data_store(dest_dir, if_empty_only = FALSE)
  expect_equal(ret, 2)
})

