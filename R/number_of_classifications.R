number_of_classifications = function(user) {
  q = glue_sql(
    "SELECT COUNT(*) as n from classification where user = {user}", 
    .con = g$pool)
  as.integer(dbGetQuery(g$pool, q)$n)
}