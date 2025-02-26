raw_expert_classification_from_database = function(con) {
  # The results of this query are cached in table "raw_expert_classification"
  # To force a refresh, simply drop the table
  table_exists = check_if_table_exists(con, "raw_expert_classification")
  if (!table_exists) {
    raw_ex_class = raw_expert_classification_to_df(con)
    DBI::dbWriteTable(con, "raw_expert_classification", raw_ex_class)
    log_it("expert_classification written to database cache")
  } else  {
    raw_ex_class = dbGetQuery(con, "SELECT * from raw_expert_classification")
  }
  raw_ex_class
}

