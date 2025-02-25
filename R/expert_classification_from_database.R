expert_classification_from_database = function(con) {
  # The results of this query are cached in table "expert_classification"
  # To force a refresh, simply drop the table
  table_exists = check_if_table_exists(con, "expert_classification")
  if (!table_exists) {
    expert_classification = raw_expert_classification_to_df(con)
    DBI::dbWriteTable(con, "expert_classification", expert_classification)
    log_it("expert_classification written to database cache")
  } else  {
    expert_classification = dbGetQuery(con, "SELECT * from expert_classification")
  }
  expert_classification
}

