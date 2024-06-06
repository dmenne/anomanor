copy_from_data_store = function(dest_dir, if_empty_only = TRUE){
  safe_create_dir(dest_dir)
  store_dir = file.path(app_sys(), "data_store", basename(dest_dir))
  dest_info = file.info(dir(dest_dir, full.names = TRUE)) %>%
    tibble::rownames_to_column() %>%
    mutate(file = basename(rowname)) %>%
    filter(!isdir)  %>%
    select(file, rowname, mtime_dest = mtime)
  if (nrow(dest_info) == 0) { # copy all if empty
    to_copy = dir(store_dir, full.names = TRUE)
  } else {
    if (if_empty_only) return(0)
    to_copy = file.info(dir(store_dir, full.names = TRUE)) %>%
      tibble::rownames_to_column() %>%
      filter(!isdir) %>%
      mutate(file = basename(rowname)) %>%
      select(file, rowname, mtime_store = mtime) %>%
      left_join(dest_info, by = "file") %>%
      filter(is.na(mtime_dest) | mtime_dest < mtime_store) %>%
      dplyr::pull(rowname.x)
  }
  file.copy(to_copy, dest_dir, recursive = TRUE)
  length(to_copy)
}




