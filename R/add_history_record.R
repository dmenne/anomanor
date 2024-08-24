add_history_record_if_required = function(min_days_since = 1) {
  latest_hist = latest_history_date()
  days_since = as.numeric(ifelse(is.null(latest_hist), 1000,
     difftime(as.POSIXlt(Sys.time()), as.POSIXlt(latest_hist), units = "days")))
  # log_it(glue("{days_since} days since last history"))
  if (days_since > min_days_since) {
    log_it(glue("Added history after {days_since} days"))
    add_history_record()
  }
  return(days_since)
}


latest_history_date = function() {
  h = dbGetQuery(g$pool, "SELECT max(history_date) from history as h")
  if (is.null(h)) return(NULL)
  h[1,]
}

first_history_date = function() {
  h = dbGetQuery(g$pool, "SELECT min(history_date) from history as h")
  if (is.null(h)) return(NULL)
  h[1,]
}

add_history_record = function(history = NULL) {
  # For empty history, generates a statistics summary table from today
  # and write it to the database
  # If a data frame for history is passed, these data are written to database directly
  if (is.null(history)) {
    sql = glue::glue(
      "select u.user, method, finalized, count(*) as cnt from classification c ",
      "left join user u on u.user = c.user ",
      "where `group` != 'admins'",
      "group by u.user, method, finalized")
    history = cbind( # using lubridate functions
      history_date = format_ISO8601(now()),
      dbGetQuery(g$pool, sql))
  }
  ret = dbAppendTable(g$pool, "history", history)
  history
}


simulate_backward_history = function(history){
  # Only for testing
  # Remove counts backwards from records in the past until nothing left
  set.seed(4711)
  n_iter = 0
  while (TRUE) {
    n_iter = n_iter + 1
    history$history_date = # using lubridate
      format_ISO8601(as_datetime(history$history_date) - hours(24*sample(2:20,1)))
    history$cnt = history$cnt - sapply(history$cnt, function(x) sample(1:(x + 2),1))
    history = history[history$cnt > 0,]
    if (nrow(history) == 0) return(n_iter)
    add_history_record(history)
  }
}


