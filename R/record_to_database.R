record_to_database = function(file, markers, time_step){
  stopifnot(is.list(g)) # requires globals
  record = file_path_sans_ext(basename(file))
  file_mtime = as.integer(file.info(file.path(g$record_dir, file))$mtime)
  if (is.null(file_mtime))
    log_stop(glue("record_to_database: {file} does not exist"))
  # REPLACE if record is already there
  anon_h = anon_from_record(record, "h")
  anon_l = anon_from_record(record, "l")
  ins_q = glue_sql(
    "INSERT OR REPLACE INTO record (record, anon_h, anon_l, file_mtime, timestep) ",
    "VALUES({record},{anon_h},{anon_l},{file_mtime},{time_step})", .con = g$pool)
  dbExecute(g$pool, ins_q)
  log_it(ins_q, force_console = FALSE)
  for (i in 1:nrow(markers)) {
    ins_q = glue_sql(
      "INSERT OR REPLACE INTO marker (record, sec, indx, annotation) VALUES(",
      "{record}, {markers$sec[i]},{markers$index[i]},{markers$annotation[i]})",
      .con = g$pool)
#    log_it(ins_q)
    dbExecute(g$pool, ins_q)
  }
  log_it(glue("Inserted {record} with {nrow(markers)} markers"))
}



