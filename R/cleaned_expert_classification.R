cleaned_expert_classification = function(con, percent_threshold = 12) {

  table_exists = check_if_table_exists(con, "cleaned_expert_classification")
  if (!table_exists) {
    ecr = raw_expert_classification(con)
    ec = ecr |> filter(percent > percent_threshold)

    log_it(paste0("Computed clean_expert_classification. Raw: ",
                  nrow(ecr), " rows, cleaned: ", nrow(ec), " rows. Threshold ",
                  percent_threshold, "%"))
    n_experts_ratings = ec  |>
      group_by(across(c(record, phase, method))) %>%
      summarize(n_total = sum(n), .groups = "drop")
    ec = ec |>
      select(-n_total, -percent) |>
      inner_join(n_experts_ratings, join_by(record, phase, method) ) |>
      mutate( percent = round(100*n/n_total))
    dbWriteTable(con, "cleaned_expert_classification", ec)
    log_it("cleaned_expert_classification written to database cache")
  } else {
    ec = dbGetQuery(con, "SELECT * from cleaned_expert_classification")
  }
  return(ec)
}
