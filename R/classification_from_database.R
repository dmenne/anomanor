classification_from_database = function(user, record, method,
                                        classification_phase, time_step) {
  if (classification_phase == "all" ||
      !(classification_phase %in% g$classification_phase_choices))
    return(NULL) # Shortcut, there are no "all" classifications
  if (is.null(record) || is.null(classification_phase))
    return(NULL)
  if (!(method %in% c("h", "l")))
    return(NULL)
  record = str_replace(record, ".txt", "")
  q = glue_sql(
    "SELECT classification, finalized, comment, t1, t2, pos1, pos2 ",
    "FROM classification ",
    "where user = {user} and method = {method} and ",
    "classification_phase = {classification_phase} ",
    "and record = {record}",
    .con = g$pool)
  sec = dbGetQuery(g$pool, q)
  if (nrow(sec) == 0)
    return(NULL)
  sec = sec[1, ]
  if (!anyNA(c(sec$t1, sec$t2, sec$pos1, sec$pos2))) {
    # x1, x2 must be corrected by dynamic start_time
    x1 = sec$t1/time_step
    x2 = sec$t2/time_step
    y1 = as.integer(round(pos_to_y(sec$pos1)))
    y2 = as.integer(round(pos_to_y(sec$pos2)))
  } else {
    x1 = x2 = y1 = y2 = NA
  }
  list(x1 = x1, y1 = y1, x2 = x2, y2 = y2,
       finalized = as.logical(sec$finalized),
       classification = sec$classification,
       comment = sec$comment)
}
