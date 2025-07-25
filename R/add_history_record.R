add_history_record_if_required = function(min_hours_since = 1) {
  latest_hist = latest_history_date()
  if (is.null(latest_hist) || is.na(latest_hist)) {
    log_it(glue("Initial history added"), TRUE)
    add_history_record()
    return(-1)
  }
  latest_hist = as.POSIXlt(latest_hist, format = "%Y-%m-%dT%H:%M")
  hours_since = round(as.numeric(
    difftime(as.POSIXlt(Sys.time()), latest_hist, units = "hours")))
  # log_it(glue("{hours_since} hours since last history update"))
  if (hours_since >= min_hours_since) {
    log_it(glue("Updated history after {hours_since} hours"))
    add_history_record()
  }
  return(hours_since)
}


latest_history_date = function() {
  h = dbGetQuery(g$pool, "SELECT max(history_date) from history as h")
  if (is.null(h)) return(NULL)
  h[1, ]
}

first_history_date = function() {
  h = dbGetQuery(g$pool, "SELECT min(history_date) from history as h")
  if (is.null(h)) return(NULL)
  h[1, ]
}


add_history_record = function(history = NULL) {
  # For history == NULL, generates a statistics summary table from today
  # and write it to the database
  # If a data frame for history is passed, these data are written to database directly
  if (is.null(history)) {
    sql = classification_user_query()
    hs = dbGetQuery(g$pool, sql)
    # Historically, column name was cnt, not n
    hs = hs |> rename(cnt = n)
    if (nrow(hs) == 0) return(hs)
    history = cbind( # using lubridate functions
      history_date = format_ISO8601(now()), hs)
  }
  # Avoid problems with unique constraints when data are too close
  try(dbAppendTable(g$pool, "history", history), silent = TRUE)
  history
}


simulate_backward_history = function(history) {
  # Only for testing
  # Remove counts backwards from records in the past until nothing left
  set.seed(4711)
  n_iter = 0
  while (TRUE) {
    n_iter = n_iter + 1
    history$history_date = # using lubridate
      format_ISO8601(as_datetime(history$history_date) - hours(24*sample(2:20, 1)))
    history$cnt = history$cnt - sapply(history$cnt, function(x) sample(1:(x/3), 1))
    history = history[history$cnt > 0, ]
    if (nrow(history) == 0) return(n_iter)
    add_history_record(history)
  }
}
