anon_from_record = function(record, method) {
  # This function does not access the database
  stopifnot(method %in% c("l", "h"))
  # Record can be a file name with full path, with or without extension
  record = paste0(
    tolower(basename(file_path_sans_ext(basename(record)))),
    "_", method)
  encode32(digest::digest2int(record),4)
}

record_from_anon = function(anon, method){
  # This function accesses table record in database
  stopifnot(method %in% c("l", "h"))
  q = glue_sql("SELECT record from record where anon_{DBI::SQL(method)} = {anon}",
               .con = g$pool)
  dbGetQuery(g$pool, q)
}

