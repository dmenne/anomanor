record_to_database = function(file, markers, time_step){
  stopifnot(is.list(g)) # requires globals
  force_console = FALSE
  record = file_path_sans_ext(basename(file))
  file_mtime = as.integer(file.info(file.path(g$record_dir, file))$mtime)
  if (is.null(file_mtime))
    log_stop(glue("record_to_database: {file} does not exist"))
  # Do not touch $ex files, these were manually marked as examples
  check_sql = glue_sql("SELECT anon_h, anon_l from record where record = {record}",
                       .con = g$pool)
  check_rec = dbGetQuery(g$pool, check_sql)
  if (nrow(check_rec) == 1) {
    if (str_starts(check_rec$anon_h, fixed("$")) ||
        str_starts(check_rec$anon_l, fixed("$"))) {
      log_it(glue("{record} not replaced because it is an example ",
                "{check_rec$anon_h}/{check_rec$anon_l}"),
           force_console = force_console)
      return(NULL)
    }
  }
  # REPLACE if record is already there
  anon_h = anon_from_record(record, "h")
  anon_l = anon_from_record(record, "l")
  # The following is required to avoid loosing classifications
  dbExecute(g$pool, "BEGIN TRANSACTION")
  dbExecute(g$pool, "PRAGMA FOREIGN_KEYS=OFF")
  ins_q = glue_sql(
    "INSERT OR REPLACE INTO record (record, anon_h, anon_l, file_mtime, timestep) ",
    "VALUES({record},{anon_h},{anon_l},{file_mtime},{time_step})", .con = g$pool)
  dbExecute(g$pool, ins_q)
  dbExecute(g$pool, "PRAGMA FOREIGN_KEYS=ON")
  dbExecute(g$pool, "COMMIT")
  log_it(ins_q, force_console = force_console)
  del_sql = glue_sql("DELETE from marker where record = {record}",
                     .con = g$pool)
  deleted_markers = dbExecute(g$pool, del_sql)
  log_it(glue("{deleted_markers} markers were deleted"), force_console = force_console)
  for (i in 1:nrow(markers)) {
    ins_q = glue_sql(
      "INSERT INTO marker (record, sec, indx, annotation) VALUES(",
      "{record}, {markers$sec[i]},{markers$index[i]},{markers$annotation[i]})",
      .con = g$pool)
#    log_it(ins_q)
    dbExecute(g$pool, ins_q)
  }
  log_it(glue("Inserted {record} with {nrow(markers)} markers"),
         force_console = force_console)
}



