raw_expert_classification_to_df = function(con) {
  q = "SELECT record, classification_phase, method, classification,
count(classification) AS n
FROM user u LEFT JOIN classification c ON u.user = c.user
WHERE finalized = 1 AND [group] = 'experts' AND u.user <> 'x_consensus'
GROUP BY classification, classification_phase, method, record"

  expert_classification = dbGetQuery(con, q)
  if (nrow(expert_classification) == 0) return(NULL)
  update_consensus_classification(expert_classification)
}
