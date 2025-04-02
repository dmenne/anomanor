get_balloon_success = function(con){
  exists_sql =
    "SELECT name FROM sqlite_master WHERE type='table' AND name='balloon_success'"
  exists = nrow(dbGetQuery(con, exists_sql )) > 0
  if (exists)
    return(tbl(con, "balloon_success") |>
      collect())
  # Table does not yet exist or was deleted
  path = normalizePath(paste0(g$database_dir, "/../data/patients"))
  pat_files =  dir(path, "*.md", full.names = TRUE)

  bs = purrr::map_df(pat_files, extract_success)
  dbWriteTable(con, "balloon_success", bs)
  bs
}

extract_success = function(pat_file) {
  txt = read_file(pat_file)[1]
  record = file_path_sans_ext(basename(pat_file))
  success = case_when(
    str_detect(txt, "not succ") ~ "no",
    str_detect(txt, "skip") ~ NA,
    str_detect(txt, "succ") ~ "yes",
    .default = NA
  )
  data.frame(record = record, success = success)
}
