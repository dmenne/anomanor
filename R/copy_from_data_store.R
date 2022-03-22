copy_from_data_store = function(dest_dir, if_empty_only = TRUE){
  safe_create_dir(dest_dir)
  store_dir = file.path(app_sys(), "data_store", basename(dest_dir))
  dest_info = file.info(dir(dest_dir, full.names = TRUE)) %>%
    tibble::rownames_to_column() %>%
    mutate(file = basename(.data$rowname)) %>%
    filter(!.data$isdir)  %>%
    select(.data$file, .data$rowname, mtime_dest = .data$mtime)
  if (nrow(dest_info) == 0) { # copy all if empty
    to_copy = dir(store_dir, full.names = TRUE)
  } else {
    if (if_empty_only) return(0)
    to_copy = file.info(dir(store_dir, full.names = TRUE)) %>%
      tibble::rownames_to_column() %>%
      filter(!.data$isdir) %>%
      mutate(file = basename(.data$rowname)) %>%
      select(.data$file, .data$rowname, mtime_store = .data$mtime) %>%
      left_join(dest_info, by = "file") %>%
      filter(is.na(.data$mtime_dest) | .data$mtime_dest < .data$mtime_store) %>%
      dplyr::pull(.data$rowname.x)
  }
  file.copy(to_copy, dest_dir, recursive = TRUE)
  length(to_copy)
}




