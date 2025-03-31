cleaned_expert_classification = function(con, percent_threshold = 12) {
  # The results of this query are cached in table "cleaned_expert_classification"
  # To force a refresh, simply drop the table
  table_exists = check_if_table_exists(con, "cleaned_expert_classification")
  if (!table_exists) {
    cl_ex_class = cleaned_expert_classification_to_df(con, percent_threshold)
    dbWriteTable(con, "cleaned_expert_classification", cl_ex_class)
    log_it("cleaned_expert_classification written to database cache")
  } else  {
    cl_ex_class = dbGetQuery(con, "SELECT * from cleaned_expert_classification")
  }
  cl_ex_class
}

