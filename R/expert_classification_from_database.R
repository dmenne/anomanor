expert_classification_from_database = function() {
  q = "SELECT * from expert_classification" # This is a view!
  expert_classification = dbGetQuery(g$pool, q)
  if (nrow(expert_classification) == 0) return(NULL)
  classified_rec =
    dbGetQuery(g$pool, "SELECT distinct record from classification")$record
  dbGetQuery(g$pool, "SELECT * from user")
  n_experts = dbGetQuery(g$pool, "SELECT count(*) as n from user
    where [group] =='experts'")$n
  n_experts_ratings = expert_classification %>%
    group_by(across(c(record,classification_phase, method))) %>%
    summarize(n_total = sum(n), .groups = "drop")
  # Join with consensus
  consensus_classification = consensus_classification_from_database()
  if (!is.null(consensus_classification)) {
    expert_classification = expert_classification %>%
      left_join(consensus_classification,
                by = c("record", "classification_phase", "method")) %>%
      rename(
        expert_classification = classification.x,
        consensus_classification = classification.y
      )
  } else {
    expert_classification$consensus_classification = NA
  }
  attr(expert_classification, "n_experts") = n_experts
  ret = expert_classification %>%
    inner_join(n_experts_ratings, join_by(record, classification_phase, method) ) |>
    mutate( percent = round(100*n/n_total))
}
