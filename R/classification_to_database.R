classification_to_database = function(user, record, method, finalized, protocol_phase, 
              classification, classification_phase, section_pars, comment) {
  stopifnot( !is.null(classification) && classification != 0 )
  stopifnot(method %in% c("l", "h"))
  if (classification_phase == "all")  # Shortcut, no "all" values are saved
    return(invisible(NULL))
  if (is.null(record) || is.null(classification_phase))
    return(NULL)
  record = str_replace(record, ".txt", "")
  if (is.null(section_pars)) {
    q = glue_sql("INSERT OR REPLACE INTO classification ",
     "(user, record, method, finalized, protocol_phase, classification,",
     "classification_phase, comment) ",
     "VALUES ({user},{record},{method},{finalized},{protocol_phase},",
     "{classification},{classification_phase},{comment})",
         .con = g$pool)

  } else {
    v = setNames(section_pars$value, str_replace(section_pars$name, " ", "_"))
    q = glue_sql(
      "INSERT OR REPLACE INTO classification ",
      "(user, record, method, finalized, protocol_phase, classification, ", 
      "classification_phase,",
      "duration, length, p_min, p_max, above_base, t1, t2, pos1, pos2, comment) ",
      "VALUES ({user},{record},{method},{finalized},{protocol_phase},", 
      "{classification},{classification_phase},",
      "{v['duration']},{v['length']},{v['p_min']},{v['p_max']},",
      "{v['above_base']},{v['t1']},{v['t2']},{v['pos1']},{v['pos2']}, {comment})",
                 .con = g$pool)
  }
  success = dbExecute(g$pool, q)
  log_it(q)
  if (success != 1)
    log_it("Failed to write classification to database", severity = "error")
  invisible(NULL)
}
