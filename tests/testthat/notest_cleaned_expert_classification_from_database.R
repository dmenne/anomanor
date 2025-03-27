Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

test_that("cleaned_expert_classification_from_database creates table if it does not exist", {
  table_exists = check_if_table_exists(g$pool, "cleaned_expert_classification")
  expect_false(table_exists)
  cl_ex = cleaned_expert_classification_from_database(g$pool)
  cl_names = c('record','classification_phase','method','classification','n',
        'consensus_classification','n_total','percent')
  expect_identical(cl_names, names(cl_ex))
  table_exists = check_if_table_exists(g$pool, "cleaned_expert_classification")
  expect_true(table_exists)
  table_exists = check_if_table_exists(g$pool, "raw_expert_classification")
  expect_true(table_exists)

})
