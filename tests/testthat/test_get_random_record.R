chs_all = list(choices = list(
  Partial = c(nse9 = "test1.txt", abc = "test7.txt"),
  ToDo = c(`$ex2` = "408245_ib.txt", nsg9 = "testnolong.txt"),
  Finalized = c(fdvt = "test2.txt")),
  icon = c("fa-battery-2", "fa-question", "fa-question", "fa-flag-checkered")
)

test_that("Return random selection, but not $ex from ToDo if it exists ", {
  chs_no_partial = list(choices = chs_all$choices[-1])
  set.seed(4711)
  expect_equal(get_random_record(chs_no_partial, "test8.txt"), "testnolong.txt")
  set.seed(4711)
  expect_equal(get_random_record(chs_no_partial, "testnolong.txt"), "testnolong.txt")
  set.seed(4711)
  expect_equal(get_random_record(chs_no_partial, "408245_ib.txt"), "408245_ib.txt")
})



test_that("One partial with selected in list tries random from ToDo ", {
  chs_one_partial = chs_all
  chs_one_partial$choices$Partial = c(nse9 = "test1.txt")
  set.seed(4711)
  expect_equal(get_random_record(chs_one_partial, "test8.txt"), "test1.txt")
  set.seed(4711)
  expect_equal(get_random_record(chs_one_partial, "test1.txt"), "testnolong.txt")

})

test_that("Return random selection from partial if it exists ", {
 set.seed(4711)
 expect_equal(get_random_record(chs_all, "test8.txt"), "test7.txt")
 set.seed(4713)
 expect_equal(get_random_record(chs_all, "test8.txt"), "test1.txt")
 set.seed(4711)
 expect_equal(as.character(get_random_record(chs_all, "test1.txt")), "test7.txt")
 set.seed(4711)
 expect_equal(as.character(get_random_record(chs_all, "test7.txt")), "test1.txt")
})


test_that("Return unchanged selection for $ex ", {
  selected = "408245_ib.txt"
  expect_equal(get_random_record(chs_all, selected ),selected)
  selected = "test7.txt"
  set.seed(4711)
  expect_equal(get_random_record(chs_all, selected ),"test1.txt")
})

test_that("NULL as selected returns null ", {
  set.seed(4711)
  expect_null(get_random_record(chs_all, NULL) )
  set.seed(4711)
  expect_equal(get_random_record(chs_all, ""),"")
})

