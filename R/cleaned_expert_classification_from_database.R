cleaned_expert_classification_from_database = function(con, percent_threshold = 12) {
  # The results of this query are cached in table "cleaned_expert_classification"
  # To force a refresh, simply drop the table
  exists_cleaned = check_if_table_exists(con, "cleaned_expert_classification")

  if (!exists_cleaned) {
    cl_ex_class = cleaned_expert_classification_to_df(con, percent_threshold)
    DBI::dbWriteTable(con, "cleaned_expert_classification", cl_ex_class)
    log_it("cleaned_expert_classification written to database cache")
  } else  {
    cl_ex_class = dbGetQuery(con, "SELECT * from cleaned_expert_classification")
  }
  cl_ex_class
}
