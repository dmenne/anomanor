#' Copy files from the data store to a destination directory
#'
#' This function copies files from a specified data store directory to a destination
#' directory. It checks whether the destination directory is empty and selectively
#' copies files based on modification timestamps.
#'
#' @param dest_dir Character string specifying the destination directory.
#' @param if_empty_only Logical indicating whether to copy all files if the destination
#'                      directory is empty (default is TRUE).
#' @return The number of files copied.
#'
#' @examples
#' \dontrun{
#' copy_from_data_store("my_destination")
#' # Copy all files from data store to "my_destination" if my_destination is empty
#'
#' # Copy only modified files from data store to "my_destination"
#' copy_from_data_store("my_destination", if_empty_only = FALSE)
#'
#'}
#' @export

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
      pull(rowname.x)
  }
  file.copy(to_copy, dest_dir, recursive = TRUE)
  length(to_copy)
}




