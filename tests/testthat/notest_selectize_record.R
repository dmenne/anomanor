Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())


test_that("selectize_record_choices returns grouped list",{
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

