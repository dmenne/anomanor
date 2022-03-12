check_valid_record = function(file, source_file = NULL) {
  stopifnot(is.list(g))
  hr_lines = try(
    readr::read_lines(file, skip_empty_rows = TRUE, lazy = FALSE,
        locale = readr::locale(encoding = "WINDOWS-1252")),
    silent = TRUE)
  # Error checking of data
  if (inherits(hr_lines, "try-error"))
    return("Not a manometry file")
  if (is.null(source_file))
    source_file = basename(file)
  annot_line = which(str_detect(hr_lines, fixed("Annotations:")))
  if (length(annot_line) == 0)
    return("No markers found in file")
  # https://community.rstudio.com/t/readr-include-spec-false/60787
  zz = textConnection(hr_lines[1:(annot_line - 2)])
  hr = read.delim(zz)
  close(zz)
  cr = try(check_record(hr, file), silent = TRUE)
  if (inherits(cr, "try-error"))
    return(cr[1])
  pm = try(parse_markers(hr_lines, annot_line, file = file), silent = TRUE)
  if (inherits(pm, "try-error"))
    return(pm[1])

  required_markers =  g$mcp %>%
    filter(.data$mtype == "r") %>%
    dplyr::pull(.data$marker)
  optional_markers =  g$mcp %>%
    filter(.data$mtype == "o") %>%
    dplyr::pull(.data$marker)
  default_markers =  g$mcp %>%
    filter(.data$mtype != "o") %>%
    dplyr::pull(.data$marker)

  markers = pm$markers$annotation
  missing = setdiff(required_markers, markers)
  unexpected = setdiff(markers,
                       c(default_markers, optional_markers, "begin"))
  unused_markers = na.omit(pm$unused_markers$annotation)
  list(
    valid_markers = setdiff(markers, c(missing, unexpected, unused_markers, "begin")),
    missing = if (length(missing) == 0) NULL else missing,
    unexpected = if (length(unexpected) == 0) NULL else unexpected,
    unused_markers = if (length(unused_markers) == 0) NULL else unused_markers,
    invalid_channels = pm$invalid_channels
  )
}


