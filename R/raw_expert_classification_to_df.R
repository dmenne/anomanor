raw_expert_classification_to_df = function(con) {
  q = "SELECT record, classification_phase, method, classification,
count(classification) AS n
FROM user u LEFT JOIN classification c ON u.user = c.user
WHERE finalized = 1 AND [group] = 'experts' AND u.user <> 'x_consensus'
GROUP BY classification, classification_phase, method, record"
  expert_classification = dbGetQuery(con, q)
  if (nrow(expert_classification) == 0) return(NULL)
  classified_rec =
    dbGetQuery(con, "SELECT distinct record from classification")$record
  dbGetQuery(con, "SELECT * from user")
  n_experts_ratings = expert_classification %>%
    group_by(across(c(record,classification_phase, method))) %>%
    summarize(n_total = sum(n), .groups = "drop")
  # Join with consensus
  consensus_classification = consensus_classification_from_database(con)
  if (!is.null(consensus_classification)) {
    expert_classification = expert_classification %>%
      left_join(consensus_classification,
                by = c("record", "classification_phase", "method")) %>%
      rename(
        classification = classification.x,
        consensus_classification = classification.y
      )
  } else {
    expert_classification$consensus_classification = NA
  }
  expert_classification %>%
    inner_join(n_experts_ratings, join_by(record, classification_phase, method) ) |>
    mutate( percent = round(100*n/n_total))
}
