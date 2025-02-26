cleaned_expert_classification_to_df = function(con, percent_threshold = 12) {
  ec = raw_expert_classification_from_database(con) |>
    filter(percent > percent_threshold)
  n_experts_ratings = ec  |>
    group_by(across(c(record, classification_phase, method))) %>%
    summarize(n_total = sum(n), .groups = "drop")
  ec |>
    select(-n_total, -percent) |>
    inner_join(n_experts_ratings, join_by(record, classification_phase, method) ) |>
    mutate( percent = round(100*n/n_total))
}
