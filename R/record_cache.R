record_cache = function(file, max_p, time_zoom,  test_hook = NULL) {
  # Read text file, interpolate it and create cache
  # Prepare names, create cache dir, and delete old cache file
  # When file has a "/", it is assumed that it is already full qualified
  # Full path is used for testing
  records_file = if (str_detect(file, "[/\\\\]")) file else
    file.path(g$record_dir, file)
  base_file = basename(records_file)
  record = file_path_sans_ext(base_file)
  if (!file.exists(records_file)) {
    # assume orphaned file
    q = paste("Record file", base_file,
              "does not exist, will be inactivated in database.",
              "Please report this to the site admin.")
    log_it(q)
    q = glue_sql("UPDATE record set valid = 0 where record ={record}", .con = g$pool)
    log_it(q, severity = "warning")
    dbExecute(g$pool, q)
    return(NULL)
  }
  cache_file = cache_file_name(base_file, time_zoom)
  png_hrm_file = png_file_name(base_file, method = 'h', max_p, time_zoom)
  png_line_file = png_file_name(base_file, method = 'l', max_p, time_zoom)
  files = list(png_hrm_file = png_hrm_file, png_line_file = png_line_file,
               cache_file = cache_file)
  # When all files are present, and database entry exists,
  # return immediately when there is no test hook
  sql = glue_sql("SELECT file_mtime FROM record WHERE record={record}",
                 .con = g$pool)
  file_mtime = dbGetQuery(g$pool,sql)
  file_mtime1 = as.integer(file.info(records_file)$mtime)
  in_db = if (nrow(file_mtime) == 0 || is.na(file_mtime1) || is.na(file_mtime[1,1]))
    FALSE  else abs(file_mtime[1,1] - file_mtime1) < 2
  if (in_db &&
      is.null(test_hook) &&
      file.exists(png_hrm_file) &&
      file.exists(cache_file) &&
      file.exists(png_line_file) ) {
    return(files)
  }
  # One file is missing or test_hook exists: remove all cached files
  unlink(cache_file)
  unlink(png_hrm_file)
  unlink(png_line_file)
  hr_lines = try(readr::read_lines(records_file,
    locale = readr::locale(encoding = "WINDOWS-1252"),
    skip_empty_rows = TRUE, lazy = FALSE), silent = TRUE)
  # Error checking of data
  if (inherits(hr_lines, "try-error") || length(hr_lines) == 0)
    log_stop(glue("Data in {file}",
          " are invalid. Have you edited these with Microsoft Word?"))
  annot_line = which(str_detect(hr_lines, fixed("Annotations:")))
  if (length(annot_line) == 0)
    log_stop(glue("No annotations found in {file}"))
  zz = textConnection(hr_lines[1:(annot_line - 2)])
  hr = read.delim()
  close(zz)
  check_record(hr, records_file)
  names(hr)[1] = "TIME" # this may be "TIEMPO"
  time_step = round(stats::median(diff(hr$TIME)),2)
  stretch_time = max(as.integer(round(time_step/0.17)), 1L)
  stretch_time = stretch_time * time_zoom
  time_step_stretched = time_step/stretch_time
  p_markers = parse_markers(hr_lines, annot_line, records_file)
  markers = p_markers$markers
  invalid_channels = p_markers$invalid_channels
  # Correct markers for offset and convert to index
  markers$sec = pmax(markers$sec - hr$TIME[1],0)
  markers$index = as.integer(round(markers$sec/time_step_stretched))

  # Save to database (only if it does not yet exists, no overwrite)
  if (time_zoom == 1) {
    record_to_database(file, markers, time_step_stretched)
  }

  nc = ncol(hr) - 3 # TIME and balloons are not interpolated
  nr = nrow(hr)
  # interpolate
  new_y = seq(1, nc, by = g$mm_resolution/g$sensor_step)
  if ("B1" %in% invalid_channels) hr$B1 = hr$B2
  if ("B2" %in% invalid_channels) hr$B2 = hr$B1
  invalid_num_channels =
    intersect(as.character(1:10), setdiff(invalid_channels, c("B1", "B2")))
  has_invalid = length(invalid_num_channels) > 0
  # Replace invalid channels by NA for na.interp
  if (has_invalid)  {
    hr[glue("X{invalid_num_channels}")] = NA
    ic = paste(invalid_channels, collapse = ", ")
    msg = glue("{basename(file)} has interpolated channels {ic}")
    log_it(msg)
  }
  ss = apply(t(as.matrix(hr[,-1])), 2,
               function(y) {
                 # Remove Balloon, Append smoothing zeroes
                 balloon = (y[1] + y[2])/2
                 y = y[-(1:2)]
                 if (has_invalid)
                   y = stinepack::na.stinterp(y)
#                 y_int = stinepack::stinterp(1:length(y), y, new_y)$y  # mm
                 y_int = stats::spline(1:length(y), y, xout = new_y)$y
                 # Re-append balloon, not interpolated
                 c( rep(balloon, g$balloon_size), rep(0, g$balloon_size), y_int )
               }
  )
  # Time resampling
  if (stretch_time != 1) {
    new_p = seq(1, ncol(ss), by = 1/stretch_time)
    ss = apply(ss, 1, function(p) {
      #y_int = stinepack::stinterp(1:length(p), p, new_p)$y
      y_int = stats::spline(1:length(p), p, xout = new_p)$y
    })
  } else {
    ss = t(ss)
  }
  # Save cache as integer for smaller size
  # We do not save the markers in cache, these should always
  # be read from the database
  ss_int = matrix(as.integer(round(ss*10)), nrow = nrow(ss))
  time = (0:(nrow(ss_int) - 1))*time_step_stretched
  saveRDS(list(data = ss_int, time = time,
               time_step = time_step_stretched),  cache_file)
  if (!is.null(test_hook))
    test_hook(ss, records_file, g$min_p, max_p, time_step_stretched)
  # create pngs
  hrm_png(ss, png_hrm_file, max_p, time_step_stretched)
  line_png(ss, png_line_file, max_p, time_step_stretched)

  files
}


check_record = function(hr, records_file) {
  if (ncol(hr) != 13)
    log_stop(paste("Only ", ncol(hr), " columns in", records_file))
  if (nrow(hr) < 100)
    log_stop(paste("Only", nrow(hr), "rows in", records_file))
}


