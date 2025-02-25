consensus_classification_from_database = function(con) {
  q = "SELECT record, classification_phase, method, classification
  FROM classification  WHERE user = 'x_consensus'"
  ret = dbGetQuery(con, q)
  if (nrow(ret) == 0) return(NULL)
  ret
}
