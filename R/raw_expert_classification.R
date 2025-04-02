raw_expert_classification = function(con) {
  # To force a regenerate, DROP TABLE raw_expert_classification
  table_exists = check_if_table_exists(con, "raw_expert_classification")
  if (!table_exists) {
    balloon_success = get_balloon_success(con)
    cs_raw = tbl(con, "classification") |>
      filter(user != "x_consensus") |>
      left_join(tbl(con, "user"), by = "user") |>
      filter(group == "experts") |>
      select(user, group, record, method,
             phase = classification_phase, classification) |>
      left_join(tbl(con, "record") |> select(record, anon_h, anon_l),
                by = "record") |>
      collect() |>
      mutate(user = str_sub(str_replace_all(user, "[aeiou\\.]", ""), 1, 4)) |>
      left_join(g$nodes |> select(id, caption, phase),
                join_by(classification == id, phase == phase))   |>
      mutate(anon = if_else(method == 'l', anon_l, anon_h)) |>
      select(-classification, -anon_l, -anon_h) |>
      rename(classification  = caption)   |>
      group_by(record, method, phase, classification) |>
      mutate(
        n = n(),
        impute = n == 1
      ) |>
      group_by(record, method, phase) |>
      mutate(
        n_total = n(),
        percent = round(100*n/n_total)
      ) |>
      ungroup() |>
      left_join(balloon_success, join_by("record"))

    dbWriteTable(con, "raw_expert_classification", cs_raw)
    log_it("raw_expert_classification written to database cache")
  } else  {
    cs_raw = dbGetQuery(con, "SELECT * from raw_expert_classification")
  }
  cs_raw
}


