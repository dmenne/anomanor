get_balloon_success = function(con){
  exists_sql =
    "SELECT name FROM sqlite_master WHERE type='table' AND name='balloon_success'"
  exists = nrow(dbGetQuery(con, exists_sql )) > 0
  if (exists)
    return(DBI::dbReadTable(con, "balloon_success"))
  # Table does not yet exist or was deleted
  anomanor_db_file = Sys.getenv("ANOMANOR_DATABASE")
  path = normalizePath(paste0(dirname(anomanor_db_file), "/../data/patients"))
  pat_files =  dir(path, "*.md", full.names = TRUE)

  bs = purrr::map_df(pat_files, extract_success)
  DBI::dbWriteTable(con, "balloon_success", bs)
  bs
}

extract_success = function(pat_file) {
  txt = read_file(pat_file)[1]
  record = basename(pat_file)
  success = case_when(
    str_detect(txt, "not succ") ~ "no",
    str_detect(txt, "skip") ~ NA,
    str_detect(txt, "succ") ~ "yes",
    .default = NA
  )
  data.frame(record = record, success = success)
}
