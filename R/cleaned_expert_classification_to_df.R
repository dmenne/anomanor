cleaned_expert_classification_to_df = function(con, percent_threshold = 12) {
  ecr = raw_expert_classification(con, g$nodes)
  ec = ecr |> filter(percent > percent_threshold)

  log_it(paste0("Computed clean_expert_classification. Raw: ",
                nrow(ecr), " rows, cleaned: ", nrow(ec), " rows. Threshold ",
                percent_threshold, "%"))
  n_experts_ratings = ec  |>
    group_by(across(c(record, classification_phase, method))) %>%
    summarize(n_total = sum(n), .groups = "drop")
  ec |>
    select(-n_total, -percent) |>
    inner_join(n_experts_ratings, join_by(record, classification_phase, method) ) |>
    mutate( percent = round(100*n/n_total))
}
