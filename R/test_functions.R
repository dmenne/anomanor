# Not used in app, only for as auxillary functions for testsin
# Callback from globals.R
copy_test_data = function(gg){
  dd = rprojroot::find_testthat_root_file("../data/md")
  file.copy(dd, dirname(gg$md_dir), recursive = TRUE)
  dd = rprojroot::find_testthat_root_file("../data/patients")
  file.copy(dd, dirname(gg$patients_dir), recursive = TRUE)
  dd = rprojroot::find_testthat_root_file("../data/records")
  file.copy(dd, dirname(gg$record_dir), recursive = TRUE)
}

cleanup_test_data = function(){
  if (Sys.getenv("R_CONFIG_ACTIVE") == 'test') {
    ano_poolClose()
    unlink(g$anomanor_data_base, recursive = TRUE)
  }
}

test_data_dir = function(basename){
  f = file.path(dirname(rprojroot::find_testthat_root_file()),
                "data/testrecords", basename)
  if (!file.exists(f))
    f = file.path(dirname(rprojroot::find_testthat_root_file()), "data/records", basename)
  stopifnot(file.exists(f))
  f
}

touch_offset = function(file, offset){
  time = strftime(Sys.time() + offset, "%Y%m%d%H%M.%S")
  return(system2("touch", c(paste("-t", time), shQuote(file))))
  #return(shell(paste("touch -t", time, shQuote(file))))
}

count_markers = function(record){
  dbGetQuery(g$pool, glue_sql(
    "SELECT COUNT(*) as n from marker where record = {record}", .con = g$pool))$n
}



get_cmp_files = function(){
  record_files = dir(g$record_dir, "^.*\\.txt$", full.names = TRUE)
  file_mtime = as.integer(unlist(lapply(record_files, function(x) file.info(x)$mtime)))
  record_time = dbGetQuery(g$pool,
                           "SELECT record, file_mtime from record where valid = 1")
  ret = tibble(
    record = basename(record_files),
    record_sans = file_path_sans_ext(basename(record_files)),
    file_mtime1 = file_mtime) %>%
    full_join(record_time, by = c("record_sans" = "record"))
  ret$record = ifelse(is.na(ret$record),
                      paste0(ret$record_sans, ".txt"),
                      ret$record)
  ret
}
