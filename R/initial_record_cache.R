initial_record_cache = function() {
  stopifnot(is.list(g)) # requires globals
  if (!database_exists(g$sqlite_path) || !g$pool$valid)
    log_stop("No database available")
  cmp_files = get_cmp_files()
  # We use the default value for max_p; for other values, the
  # background graphics will be created on the fly
  for (i in 1:nrow(cmp_files)) {
    cf = cmp_files[i,]
    record_cache(cf$record, max_p = 100, time_zoom = 1)
  }
  NULL
}
