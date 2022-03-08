markers_for_record = function(record) {
  q = glue_sql(
    "SELECT sec, indx as 'index', annotation, show from marker where record = ",
    "{file_path_sans_ext(record)} and show = 1 order by indx", .con = g$pool)
  dbGetQuery(g$pool, q) %>% 
    as_tibble()
}

