cleaned_expert_classification = function(con, percent_threshold = 12) {

  table_exists = check_if_table_exists(con, "cleaned_expert_classification")
  if (!table_exists) {
    rec1 = raw_expert_classification(con)

    # Impute entries with count = 1
    set.seed(4711)
    rec = rec1 |>
      group_by(record, method, phase) |>
      mutate(
        classification = ifelse(impute, NA, classification),
        classification = ifelse(is.na(classification),
                                sample(na.omit(classification),1),
                                classification)
      ) |>
      group_by(record, method, phase, classification) |>
      mutate(n = n()) |>
      group_by(record, method, phase) |>
      mutate(
        n_total = n(),
        percent = round(100*n/n_total)
      )
    dbWriteTable(con, "cleaned_expert_classification", rec)
    log_it("cleaned_expert_classification written to database cache")
  } else {
    rec = dbGetQuery(con, "SELECT * from cleaned_expert_classification")
  }
  cc = consensus_classification(con)
  rec = rec |>
    left_join(cc, by = join_by(record, phase, method) )
  return(rec)
}
