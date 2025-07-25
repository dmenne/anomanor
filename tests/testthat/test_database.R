Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())

valid_fa = c("fa-battery-2", "fa-battery-1", "fa-battery-3",
  "fa-question", "fa-flag-checkered", "fa-check")

test_that("helper function return state of table", {
  ex =  check_if_table_exists(g$pool, "ano_logs")
  expect_true(ex)
  ex =  check_if_table_exists(g$pool, "nonsense")
  expect_false(ex)
})

test_that("raw_expert_classification cache table is created", {
  ex = check_if_table_exists(g$pool, "raw_expert_classification")
  expect_false(ex)
  ex_db = raw_expert_classification_from_database(g$pool)
  expect_gt(nrow(ex_db), 10)
  ex = check_if_table_exists(g$pool, "raw_expert_classification")
  expect_true(ex)
  dbExecute(g$pool, "DROP TABLE raw_expert_classification")
  ex = check_if_table_exists(g$pool, "raw_expert_classification")
  expect_false(ex)
})

test_that("cleaned_expert_classification cache table is created and is cleaned", {
  ex = check_if_table_exists(g$pool, "cleaned_expert_classification")
  expect_false(ex)
  raw_ex_db = raw_expert_classification_from_database(g$pool)
  percent_threshold = 25
  cleaned_ex_db = cleaned_expert_classification_from_database(g$pool, percent_threshold)
  expect_equal(nrow(raw_ex_db), nrow(cleaned_ex_db))
  expect_lte(min(cleaned_ex_db$percent),  percent_threshold)
  ex = check_if_table_exists(g$pool, "cleaned_expert_classification")
  expect_true(ex)
  dbExecute(g$pool, "DROP TABLE cleaned_expert_classification")
  ex = check_if_table_exists(g$pool, "cleaned_expert_classification")
  expect_false(ex)
})


test_that("timestamp is updated when classification is saved and no data deleted", {
  # This is an unsaved record
  ret = classification_from_database("x_bertha", "test1", "l", "tone", 0.17)
  n1 = n_classifications()
  expect_type(ret, "list")
  expect_equal(length(ret), 7)
  timestamp_sql = glue(
    "SELECT timestamp from classification where user = 'x_bertha' and record = 'test1' ",
    "and method = 'l' and classification_phase = 'tone'")
  ts1 = dbGetQuery(g$pool, timestamp_sql)
  expect_equal(nrow(ts1), 1)
  classification_to_database("x_bertha", "test1", "l", 1, "begin", 9, "tone",
                              NULL, "comment")
  ts2 = dbGetQuery(g$pool, timestamp_sql)
  expect_gt(ts2, ts1)
  expect_equal(n_classifications(), n1)
})



test_that("selectize_record_choices returns grouped list", {
  record_summary = tibble(
    record = paste0("test", 1:10),
    nfinalized = sample(c(0:3, NA, NA), 10, replace = TRUE),
    anon = purrr::map_chr(record, anon_from_record, "h")
  ) %>%
    mutate(
      icon = case_when(
        is.na(nfinalized) ~ "fa-question",
        nfinalized == 0 ~ "fa-battery-1",
        nfinalized == 1 ~ "fa-battery-2",
        nfinalized == 2 ~ "fa-battery-3",
        nfinalized == 3 ~ "fa-flag-checkered",
      )
    )
  ret = selectize_record_choices(record_summary)
  expect_equal(names(ret), c("choices", "icon"))
  checkmate::expect_subset(names(ret$choices), c("Partial", "ToDo", "Finalized"))
  checkmate::expect_subset(names(ret$icon), valid_fa)
})

test_that("classification_record_summary with valid name returns nfinalized ", {
  ret = classification_record_summary("aaron", method = "h" )
  expect_s3_class(ret, "tbl_df")
  checkmate::expect_subset(c("test1", "test2"), ret$record)

  expect_type(ret$nfinalized, "integer")
  expect_equal(names(ret), c("record", "nfinalized", "icon", "anon"))
  expect_true(all(ret$icon %in% valid_fa))
  # Check bidirectional mapping. record_from_anon needs entry in database
  expect_equal(anon_from_record(
      record_from_anon(ret$anon[1], 'h')$record[1], 'h'), ret$anon[1])
})

test_that("classification_record_all returns tibble", {
  ret = classification_record_all()
  expect_s3_class(ret, "tbl_df")
  expect_equal(names(ret), c("record", "method", "anon", "n_ratings"))
  expect_setequal(ret$anon, c('bhhv', "nse9", "ymrt", "fdvt"))
})

test_that("Without keycloak, keycloak_users returns values from database", {
  ret = keycloak_users()$user
  checkmate::expect_character(g$test_users)
  checkmate::expect_subset(ret, c(g$test_users, "test", "x_consensus"))
})


test_that("classification_phase_summary gives valid return for existing user", {
  ret = classification_phase_summary("aaron", "test2", "h")
  expect_s3_class(ret, "tbl_df")
  checkmate::expect_set_equal(ret$classification_phase, c("All", "rair", "tone", "coord"))
  expect_true(all(ret$icon %in% valid_fa))
  checkmate::expect_set_equal(ret$method, c(NA, "h"))

  ret = classification_phase_summary("aaron", "test2", "l")
  expect_s3_class(ret, "tbl_df")
  checkmate::expect_set_equal(ret$method, c(NA, "l"))
})

test_that("classification_phase_summary with invalid user/group returns question icons ",
          {
  ret = classification_phase_summary("notknown", "testxxx", "h" )
  expect_s3_class(ret, "tbl_df")
  checkmate::expect_set_equal(ret$classification_phase, c("All", "rair", "tone", "coord"))
  expect_equal(unique(ret$icon), "fa-question")
})

test_that("classification_statistics returns valid user stats of hrm", {
  ret = classification_statistics(method = "h")
  expect_equal(nrow(ret), 14)
  expect_s3_class(ret, "tbl_df")
  expect_equal(names(ret), c("record", "group", "phase",
                             "classification", "n", "short"))
  checkmate::expect_set_equal(ret$record, c("test1", "test2"))
  checkmate::expect_set_equal(ret$group,  c("experts", "trainees"))
  checkmate::expect_set_equal(ret$phase,  c("coord", "rair", "tone"))
  expect_true(all(ret$classification >= 1))
  shorts = unique(na.omit(g$nodes$short))
  expect_true(all(ret$short %in% shorts))
})

test_that("classification_statistics with method 'l' return valid user stats of line", {
  ret = classification_statistics(method = "l")
  expect_gte(nrow(ret), 18)
  shorts = unique(na.omit(g$nodes$short))
  expect_true(all(ret$short %in% shorts))
})

test_that("classification_statistics with use_group given returns stats of hrm", {
  ret = classification_statistics(use_group = "experts", method = 'h')
  expect_equal(nrow(ret), 10)
  checkmate::expect_set_equal(ret$group, "experts")
})

test_that("classification_statistics with invalid use_group raises", {
  expect_error(classification_statistics(use_group = "blub", method = 'h'))
})

test_that("classification_statistics_wide with default arguments returns list of tables with method hrm", {
  ret = classification_statistics_wide(method = 'h')
  expect_equal(names(ret), c("rair", "tone", "coord"))
  rair = ret$rair
  expect_s3_class(rair, "tbl_df")
  expect_true(all(names(rair) %in% c('record', 'Areflexia_experts',
  'Areflexia_trainees','Ok_experts','Ok_trainees','sum_experts','sum_trainees')))
})

test_that("classification_statistics_wide with method 'l' returns list of tables with method line", {
  ret = classification_statistics_wide(method = "l")
  expect_equal(names(ret), c("rair", "tone", "coord"))
  rair = ret$rair
  expect_s3_class(rair, "tbl_df")
  expect_true(all(names(rair) %in% c('record', 'Areflexia_experts',
                                     'Areflexia_trainees','Ok_experts','Ok_trainees','sum_experts','sum_trainees')))
})


test_that("classification_statistics_wide with invalid use_group raises", {
  expect_error(classification_statistics_wide(use_group = "blub", method = 'h'))
})

test_that("classification_statistics_wide with invalid classification name raises", {
  expect_error(classification_statistics_wide(classification_name = "blub",
                                              method = 'h'))
})


test_that("classification_statistics_wide with one group returns restricted wide list", {
  ret = classification_statistics_wide(use_group = "experts", method = 'h')
  expect_equal(names(ret), c("rair", "tone", "coord"))
  rair = ret$rair
  expect_s3_class(rair, "tbl_df")
  checkmate::expect_subset(names(rair), c('record', 'Areflexia_experts',
                              'Ok_experts','sum_experts', 'sum_trainees'))
})

test_that("classification_statistics_wide with explicit classification name", {
  ret = classification_statistics_wide(classification_name = "classification")
  expect_equal(names(ret), c("rair", "tone", "coord"))
  rair = ret$rair
  expect_s3_class(rair, "tbl_df")
  checkmate::expect_subset(names(rair),  c('record', '2_experts', '2_trainees',
     '3_experts', '3_trainees', 'sum_experts', 'sum_trainees'))
})

test_that("classification_user_statistics returns tibble", {
  ret = classification_user_statistics()
  expect_s3_class(ret, "tbl_df")
  expect_equal(names(ret),
    c('user', 'email', 'name', 'verified', 'group', 'method', 'saved', 'finalized'))
  checkmate::expect_set_equal(ret$method, c("l", "h"))
  expect_gte(nrow(ret), 4)
  expert_saved = ret %>%
    filter(group == "experts")
  expect_equal(sum(expert_saved$saved), 0)
  expect_true(all(expert_saved$finalized == 6))
})

expected_names =  c('record', 'classification_phase', 'method', 'classification',
            'n', 'percent', 'majority_classification', 'clinical_classification')

test_that("raw_expert_classification_from_database returns tibble", {
  ret = raw_expert_classification_from_database(g$pool)
  expect_equal(names(ret), expected_names)
  checkmate::expect_set_equal(ret$record, c("test1", "test2"))
})

test_that("cleaned_expert_classification_from_database returns tibble", {
  ret = cleaned_expert_classification_from_database(g$pool)
  expect_equal(names(ret), expected_names)
  checkmate::expect_set_equal(ret$record, c("test1", "test2"))
})



test_that("classification_from_database returns list", {
  ret = classification_from_database("x_bertha", "test1", 'l', "tone", 0.17)
  expect_type(ret, "list")
  expect_equal(length(ret), 7)
  nams = c('x1', 'y1', 'x2', 'y2', 'finalized', 'classification', 'comment')
  expect_equal(names(ret), nams)
  ret = classification_from_database("x_dora", "test2", "h", "tone", 0.17)
  expect_type(ret, "list")
  expect_equal(length(ret), 7)
  expect_equal(names(ret), nams)
})

test_that("Invalid classification_from_database requests return NULL", {
  ret = classification_from_database("x_bertha", "test1", 'l', "blub", 0.17)
  expect_null(ret)
  ret = classification_from_database("x_bertha", "test1", 'l', "all", 0.17)
  expect_null(ret)
  ret = classification_from_database("x_bertha", NULL, 'l', "tone", 0.17)
  expect_null(ret)
  ret = classification_from_database("x_bertha", "test1", 'x', "tone", 0.17)
  expect_null(ret)
  ret = classification_from_database("xxxxx", "test1", 'l', "tone", 0.17)
  expect_null(ret)
})

test_that("markers_for_record returns data", {
  ret = markers_for_record("test1")
  expect_s3_class(ret, "tbl_df")
  expect_equal(names(ret),
               c('sec', 'index', 'annotation', 'show'))
  expect_equal(ret$annotation, c('begin', 'Rest', 'Squeeze 1',
  'Squeeze 2', 'Long Squeeze', 'Cough', 'Push 1', 'Push 2', 'Push 3',
  'RAIR'))
})


test_that("invalid parameters in classification_to_database return NULL", {
  # All valid cases are implicitly tested a few thousands of times
  # "all" as classification_phase
  ret = classification_to_database("sa_admin", "any", "l", TRUE,
                                   "begin", 3, "all", NULL, "")
  expect_null(ret)
  # record is NULL
  ret = classification_to_database("sa_admin", NULL, "l", TRUE,
                                   "begin", 3, "tone", NULL, "")
  expect_null(ret)
  # classification_phase is NULL
  ret = classification_to_database("sa_admin", "any", "l", TRUE,
                                   "begin", 3, NULL, NULL, "")
  expect_null(ret)
})

test_that("is_example returns logical", {
  expect_false(is_example("test1"))
})

# This must be last in file because it will delete !
test_that("Recursive deletion works", {
  pool = g$pool
  n_user =
    dbGetQuery(pool, "SELECT count(*) from classification where user like 'x_%'")$count
  expect_gt(n_user,  0)
  ret = dbExecute(pool, "DELETE from user where user like 'x_%'")
  n_user =
    dbGetQuery(pool, "SELECT count(*) from classification where user like 'x_%'")$count
  expect_equal(n_user, 0)
  ret = dbExecute(pool, "DELETE FROM record where record='test1'")
  expect_gt(ret, 1)
  ret = dbGetQuery(pool, "SELECT DISTINCT record from classification")$record
  expect_equal(ret, "test2")
  ret = dbExecute(pool, "DELETE FROM record where record='test2'")
  expect_gt(ret, 1)
  ret = dbGetQuery(pool, "SELECT DISTINCT record from classification")
  expect_equal(nrow(ret), 0)
  ret = dbExecute(pool, "DELETE from user")  # Total cleanup
})

