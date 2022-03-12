parse_markers = function(hr_lines, annot_line = 1, file = "testfile") {
  # Find annotations
  if (length(annot_line) == 0)
    log_stop("There are no annotations in this file")
  # https://community.rstudio.com/t/readr-include-spec-false/60787
  hr_markers = str_trim(hr_lines[(annot_line + 1):length(hr_lines)])
  # Replace first space after number
  hr_markers = str_replace(hr_markers, "^([-\\d\\.]+) ", "\\1\t")
  # Only keep markers with a hash #
  hr_unused_markers = hr_markers[!str_detect(hr_markers, "#")]
  zz = textConnection(hr_unused_markers)
  unused_markers = read.delim(zz, header = FALSE,
                              col.names =  c("sec", "annotation")) %>%
    as_tibble() %>%
    mutate(annotation = str_trim(.data$annotation))
  close(zz)
  hr_markers = hr_markers[str_detect(hr_markers, "#")]
  # And remove the hashes
  hr_markers = str_replace(hr_markers, "# *", "")
  if (length(hr_markers) == 0)
    log_stop("No valid markers in file")
  zz = textConnection(hr_markers)
  markers = read.delim(zz, header = FALSE,
                       col.names =  c("sec", "annotation")) %>%
    mutate(annotation = str_trim(.data$annotation))
  close(zz)
  invalid_channels = markers %>%
    filter(.data$sec < 0) %>%
    pluck("annotation")
  allowed_invalid_channels = c("B1", "B2", paste(1:10))
  if (!is.null(invalid_channels) && !invalid_channels %in% allowed_invalid_channels)
    log_stop(
      glue("Invalid channel(s) {paste(invalid_channels, collapse = ', ')}.",
           " Only {paste(allowed_invalid_channels, collapse = ', ')} are permitted.")
    )
  markers = markers %>%
    filter(.data$sec >= 0)
  list(
    markers = bind_rows(tribble(~sec, ~annotation, 0, "begin"),
                        markers),
    invalid_channels = invalid_channels,
    unused_markers = unused_markers
  )
}

