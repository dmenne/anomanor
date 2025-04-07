cleaned_expert_classification_to_df = function(con, percent_threshold = 12) {
    q = "SELECT record, classification_phase, method, classification
FROM user u LEFT JOIN classification c ON u.user = c.user
WHERE finalized = 1 AND [group] = 'experts' AND u.user <> 'x_consensus'"

  classification = dbGetQuery(con, q)
  if (nrow(classification) == 0) return(NULL)
  impute_me = classification |>
    group_by(record, classification_phase, method, classification) |>
    summarize(n = n(), .groups = "drop_last"  ) |>
    dplyr::add_tally(n, name = "n_total") |>
    filter(round(100*n/n_total) < percent_threshold)  |>
    select(record, classification_phase, method, classification) |>
    mutate(impute = TRUE) |>
    distinct()

  set.seed(4711) # For reproducible sample
  classification_i = classification |>
    left_join(impute_me,
              by = c("record", "classification_phase", "method", "classification")) |>
    group_by(record, classification_phase, method) |>
    mutate(classification = if_else(is.na(impute), classification, NA_integer_ )) |>
    mutate(classification = if_else(is.na(classification),
                                    sample(na.omit(classification), 1),
                                     classification)) |>
    select(-impute) |>
    group_by(record, classification_phase, method, classification)  |>
    summarize(n = n(), .groups = "drop") |>
    arrange(record, classification_phase, method)

    update_consensus_classification(classification_i)
}
