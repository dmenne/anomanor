cache_file_name = function(file, time_zoom) {
  glue("{g$record_cache_dir}/{file_path_sans_ext(file)}_{time_zoom}.rds")
}

png_phase_file_name = function(file, method, max_p, active_begin,
                       active_width, window_width, phase_label, time_zoom) {
  stopifnot(method %in% c("l", "h"))
  # hashed file name
  anon = anon_from_record(file, method)
  phase_label = str_to_lower(str_replace(phase_label, " ", ""))
  cache_key = glue(
    "{max_p}_{active_begin}_{phase_label}_{active_width}_{window_width}_{time_zoom}.png")
  glue("{g$png_dir}/{anon}_{cache_key}")
}

png_file_name = function(file, method, max_p, time_zoom) {
  stopifnot(method %in% c("l", "h"))
  anon = anon_from_record(file, method)
  glue("{g$png_dir}/{anon}_{max_p}_{time_zoom}.png")
}

legend_file_name = function(max_p) {
  # Use legend_from_line_file_name for line plots
  glue::glue("{g$png_dir}/scale_{max_p}_h.png")
}

legend_from_line_file_name = function(png_line_file) {
  file.path(dirname(png_line_file), paste0("scale_", basename(png_line_file)))
}

record_start_time = function(active_begin, active_width, window_width, image_width) {
  if (active_begin == 0) return(0)
  start_time = max(active_begin - (window_width - active_width) / 2, 0 )
  min(start_time, max(image_width - window_width, 0))
}

get_app_user = function() {
  user = Sys.getenv("SHINYPROXY_USERNAME")
  if (is.null(user) ||  user == "")
    user = g$config$app_user
  if (user == "random")
    user = encode32(sample.int(.Machine$integer.max, 1))
  if (is.null(user))
    log_stop("Both SHINYPROXY_USERNAME and config.app_user are NULL")
  user
}

get_app_groups = function(app_user){
  # Getting groups from keycloak under Shinyproxy does not work
  # group = Sys.getenv("SHINYPROXY_USERGROUPS")
  if (keycloak_available()) {
    # nocov start
    groups = g$keycloak$user_groups(app_user)["name"]
    # When name is not found or no group, default app group
    if (is.null(groups) || nrow(groups) == 0)
      return(g$config$app_groups)
    if (nrow(groups) == 1)
      return(as.character(groups))
    return(paste(unlist(groups), collapse = " "))
    # nocov end
  } else {
    g$config$app_groups
  }
}

ano_modal = function(markdown_file){
  markdown_html = render_md(markdown_file)
  html = HTML(readr::read_file(markdown_html))
  showModal(modalDialog(size = "l", easyClose = TRUE, html))
}

safe_create_dir = function(dir){
  # return NULL if exists, otherwise result of dir.create
  if (dir.exists(dir)) return(NULL)
  ret = try(dir.create(dir))
  if (!dir.exists(dir)) {
    log_stop(glue("Could not create {dir}} \n"))
  } else {
    log_it(glue("Created {file_path_as_absolute(dir)}\n"), force_console = FALSE)
  }
}

save_file_rename = function(from, to){
  if (!file.exists(from)) return (NULL)
  file.rename(from, to)
}

y_to_pos = function(y){
  (y - 2*g$balloon_size)*g$image_y_to_position_fac
}

pos_to_y = function(pos){
  pos/g$image_y_to_position_fac + 2*g$balloon_size
}

