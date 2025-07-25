is_example = function(record) {
  record = file_path_sans_ext(record)
  q = glue_sql("select anon_h like '$%' or anon_l like '$%' as is_example ",
  "from record  where record = {record}", .con = g$pool)
  qq = dbGetQuery(g$pool, q)
  qq$is_example == 1
}
