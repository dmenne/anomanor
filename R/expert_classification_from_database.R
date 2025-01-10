expert_classification_from_database = function() {
  q = "SELECT * from expert_classification" # This is a view!
  expert_classification = dbGetQuery(g$pool, q)
  if (nrow(expert_classification) == 0) return(NULL)
  n_rec = dbGetQuery(g$pool, "SELECT count(*) as n from record where valid = 1")$n
  n_experts = dbGetQuery(g$pool, "SELECT count(*) as n from user
    where [group] =='experts' and user != 'x_consensus'")$n
  n_experts_ratings = expert_classification %>%
    group_by(classification_phase) %>%
    summarize(n = sum(n))
  # Join with consensus
  consensus_classification = consensus_classification_from_database()
  if (!is.null(consensus_classification)) {
    expert_classification = expert_classification %>%
      left_join(consensus_classification, by = c("record", "classification_phase")) %>%
      mutate(
        expert_classification = classification.x == classification.y,
        classification.y = NULL
      ) %>%
    rename(classification = classification.x)
  } else {
    expert_classification$expert_classification = FALSE
  }
  n_experts_ratings = n_experts_ratings$n
  # TODO: This code is wrong
  complete_expert_ratings = all(n_experts_ratings == 2*n_rec*n_experts)
  attr(expert_classification, "n_experts") = n_experts
  attr(expert_classification, "n_rec") = n_rec
  # DEBUG
  complete_expert_ratings = TRUE
  attr(expert_classification, "complete_expert_ratings") = complete_expert_ratings
  expert_classification %>%
    mutate( percent = round(100*n/n_experts))
}
