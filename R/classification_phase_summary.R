classification_phase_summary = function(user, record, method) {
  stopifnot(method %in% c("l", "h"))
  if (rlang::is_empty(record))
    return(invisible(NULL))
  q = glue_sql("SELECT classification_phase, finalized, method from classification ",
               "where user={user} and record={record} and method={method}", .con = g$pool)
  ps = tibble(classification_phase = c("rair", "tone", "coord"))
  pp = dbGetQuery(g$pool, q)
  ps = ps %>%
    left_join(pp, by = "classification_phase") |>
    mutate(
      icon = case_when(
        is.na(finalized) ~ "fa-question",
        finalized == 0 ~ "fa-check",
        finalized == 1 ~ "fa-flag-checkered"
      )
    )
  n_finalized = sum(ps$finalized, na.rm = TRUE)
  icon = case_when(
    is.na(n_finalized) ~ "fa-exclamation",
    n_finalized == 0 ~ "fa-question",
    n_finalized == 1 ~ "fa-battery-2",
    n_finalized == 2 ~ "fa-battery-3",
    TRUE ~ "fa-flag-checkered")
  bind_rows(
    tibble(classification_phase = "All", icon = icon),
    ps
  ) %>%
    mutate(
      finalized = NULL
    )
}

