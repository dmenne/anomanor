#' @param msg Text to be logged
#'
#' @param force_console Write also to console when true
#' @param severity Use "info" or "error"
#'
#' @export
log_it = function(msg, force_console = FALSE, severity = "info") {
  if (!exists("g")) { # requires globals
    if (force_console) cat("No globals log:\n ", msg, "\n")
    return(invisible(NULL))
  }
  msg = as.character(msg)
  tm = as.POSIXlt(Sys.time(), "UTC")
  force_console = force_console || g$config$force_console
  if (force_console || (!is.null(g$config) && is.list(g$config) && g$config$force_console))
    cat(msg, "\n")
  if (!is.null(g$pool) && DBI::dbIsValid(g$pool)) {
    iso = strftime(tm , "%Y-%m-%d %H:%M:%S")
    q = glue_sql("INSERT into ano_logs (time, severity, message) ",
                 "values ({iso}, {severity}, {msg})", .con = g$pool)
    dbExecute(g$pool, q)
  }
  invisible(NULL)
}

log_stop = function(...) {
  msg = paste0(...)
  log_it(msg = msg, force_console = FALSE, severity = "error")
  stop(msg, call. = FALSE)
}
