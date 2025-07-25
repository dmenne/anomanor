test_that("encode32 gives valid string", {
  expect_equal(encode32(312), "2jaaaaa")
  expect_equal(encode32(312, 5), "2jaaa")
  expect_equal(encode32(312, 0), "2jaaaaa")
})
