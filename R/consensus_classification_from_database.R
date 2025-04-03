consensus_classification = function(con) {
  q = "
SELECT record, classification_phase as phase, c.method,
n.caption as consensus_classification, n.id as consensus_id
FROM classification c LEFT JOIN nodes n
ON n.phase = c.classification_phase and n.id = c.classification
WHERE c.user = 'x_consensus'"
  ret = dbGetQuery(con, q)
  if (nrow(ret) == 0) return(NULL)
  ret
}
