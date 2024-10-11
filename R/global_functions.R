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

get_app_user = function(session = NULL) {
  user = NULL
  if (!is.null(session))
    user = session$request$HTTP_X_SP_USERID
  if (is.null(user) ||  user == "")
    user = Sys.getenv("SHINYPROXY_USERNAME")
  if (is.null(user) ||  user == "")
    user = g$config$app_user
  if (!is.null(user) && user == "random")
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
  # return FALSE if directory exists, otherwise TRUE
  if (dir.exists(dir)) return(FALSE)
  ret = try(dir.create(dir, recursive = TRUE))
  if (!dir.exists(dir)) {
    log_stop(glue("Could not create {dir}} \n"))
  } else {
    log_it(glue("Created {file_path_as_absolute(dir)}\n"), force_console = FALSE)
  }
  return(TRUE)
}

save_file_rename = function(from, to){
  if (!file.exists(from)) return(NULL)
  file.rename(from, to)
}

y_to_pos = function(y){
  (y - 2*g$balloon_size)*g$image_y_to_position_fac
}

pos_to_y = function(pos){
  pos/g$image_y_to_position_fac + 2*g$balloon_size
}

log_it = function(msg, force_console = FALSE, severity = "info") {
  if (!exists("g")) { # requires globals
    if (force_console) cat("No globals log:\n ", msg, "\n")
    return(invisible(NULL))
  }
  msg = as.character(msg)
  tm = as.POSIXlt(Sys.time(), "UTC")
  force_console = force_console || g$config$force_console
  if (force_console || (!is.null(g$config) && is.list(g$config) && g$config$force_console))
    cat(file = stderr(), "\n", msg, "\n")
  if (!is.null(g$pool) && DBI::dbIsValid(g$pool)) {
    op <- options(digits.secs = 2)
    iso = strftime(tm , tz = "Europe/Berlin", "%Y-%m-%d %H:%M:%OS")
    q = glue_sql("INSERT into ano_logs (time, severity, message) ",
                 "values ({iso}, {severity}, {msg})", .con = g$pool)
    dbExecute(g$pool, q)
  }
  invisible(NULL)
}

log_stop = function(...) {
  msg = paste0(...)
  log_it(msg = msg, force_console = FALSE, severity = "error")
  stop(msg, call. = FALSE)
}

keycloak_available = function(){
  stopifnot(exists("g") && is.list(g)) # globals
  if (!g$config$use_keycloak) return(FALSE)
  if (stringr::str_starts(g$config$keycloak_site, "keycloak"))
    g$config$keycloak_port = 443
  !is.na(pingr::ping_port(g$config$keycloak_site, g$config$keycloak_port,
                          count = 1, timeout = 0.1))
}

keycloak_users = function(){
  stopifnot(is.list(g)) # requires global
  # Without keycloak, get user surrogate from database
  if (is.null(g$keycloak) || !keycloak_available() || !g$keycloak$active()) {
    q = glue_sql("SELECT user, [group] from user", .con = g$pool)
    # log_it(paste("keycloak_users ", q))
    users = dbGetQuery(g$pool, q)    %>%
      transmute(
        user = user,
        email = "none",
        name = user,
        verified = TRUE,
        group = group
      )
    return(users)
  }
  # nocov start
  users = g$keycloak$users()

  if (is.null(users) || rlang::is_empty(users) ) {
    log_stop("Keycloak did not return users")
    return(NULL)
  }
  # We prioritize groups, only the dominant is kept
  users = users %>%
    mutate(
      group = case_when(
        admins ~ 'admins',
        experts ~ 'experts',
        TRUE ~ 'trainees'
      )
    ) %>%
    transmute(
      user = username,
      email = email,
      name = ifelse(is.na(firstName) | is.na(lastName),
                    "", paste(firstName, lastName)),
      verified = emailVerified,
      group = group
    )
  # log_it(paste("Users:", paste(users$user, collapse = ", ")))
  users
  # nocov end

}

app_sys = function(...){
  system.file(..., package = "anomanor")
}

ano_bttn = function(inputId, icon = inputId, color = "success") {
  # https://community.rstudio.com/t/use-of-open-source-icons-in-shiny/110056/5
  # Could not get the above to work with actionButton
  shinyWidgets::actionBttn(inputId = inputId, label = str_to_title(inputId),
                           size = "sm", block = TRUE ,
                           icon = icon(icon),
                           style = "material-flat",
                           color = color
  )
}

# Use tippy directly in ui for selectize boxes
tippy_all = function() {
  tippy_main_text = tibble::tribble(
    ~id, ~text,
    "save", "Save temporarily.<br><small>Use <b>Finalize</b> when you are sure you do not plan later edits</small>",
    "cancel", "Cancel classification",
    "finalize", "Save and make read-only.<br><small>After finalization, trainees will be shown expert classification choices and consensus result.</small>"
  )
  invisible(apply(tippy_main_text, 1, function(x) tippyThis(x["id"], x["text"])))
}

getenv_r_config_active = function(){
  stringr::str_trim(Sys.getenv("R_CONFIG_ACTIVE"))
}


tryCatch.W.E <- function(expr)
{
  W <- NULL
  w.handler <- function(w) { # warning handler
    W <<- w
    invokeRestart("muffleWarning")
  }
  list(value = withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = w.handler), warning = W)
}

n_classifications = function() {
  q = "SELECT COUNT() as n from classification as n"
  dbGetQuery(g$pool, q)$n
}

