cleaned_expert_classification_from_database = function(con) {
  # The results of this query are cached in table "cleaned_expert_classification"
  # To force a refresh, simply drop the table
  table_exists = check_if_table_exists(con, "cleaned_expert_classification")
  if (!table_exists) {
    cleaned_expert_classification = expert_classification_from_database(con)
    DBI::dbWriteTable(con, "cleaned_expert_classification", cleaned_expert_classification)
    log_it("cleaned_expert_classification written to database cache")
  } else  {
    cleaned_expert_classification = dbGetQuery(con,
                                  "SELECT * from cleaned_expert_classification")
  }
  cleaned_expert_classification
}

