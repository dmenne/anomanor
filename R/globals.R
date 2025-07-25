# This is file globals(sic!).R, not Shiny special global.R
# Variables in this function are can be accessed via g$,
# as defined in run_app.R
# Not needed to run without Check
# Warning: globals: no visible binding for global variable g
utils::globalVariables("g")

globals = function() {
#  options(warn = 2)
  conflicts_prefer(dplyr::filter, dplyr::lag, .quiet = TRUE)
  conflicts_prefer(dplyr::intersect, dplyr::setdiff, dplyr::setequal, dplyr::union,
                   .quiet = TRUE)
  ptm = proc.time()
  options(shiny.error = browser)
  # https://github.com/rstudio/shiny/issues/3626
  options(shiny.useragg = TRUE)

  # Default configuration must set globally
  # By default, user is sa_admin
  active_config = getenv_r_config_active()
  # See .Renviron file for settings
  # Do not use the default in Sys.getenv here, problem later
  # See valid values in config.yml
  valid_config = c("sa_trainee", "sa_admin", "sa_expert", "test",
                   "test_expert", "keycloak_devel",
                   "keycloak_test",
                   "sa_consensus",
                   "keycloak_production", "sa_random_trainee")
  stopifnot(active_config %in% valid_config)

  # Renviron_production is not saved in git
  is_windows = Sys.info()["sysname"] == "Windows"
  env_file_base =  case_when(
      active_config == "keycloak_devel" ~ "Renviron_devel",
      active_config == "keycloak_production" ~ "Renviron_production",
      active_config == "keycloak_test" ~ "Renviron_keycloak_test",
      is_windows ~ "Renviron_windows",
      TRUE ~ "Renviron_devel")
  root_dir = app_sys()
  env_file = file.path(root_dir, env_file_base)
  if (!file.exists(env_file))
    stop(paste(dir(root_dir), collapse  = "\n"), call. = FALSE)
#    stop("Environment file ", env_file, " does not exist", call. = FALSE)
  readRenviron(env_file)
  if (getenv_r_config_active() != active_config) {
    cat("R_CONFIG_ACTIVE --", getenv_r_config_active(), "--  ", active_config, "\n")
    stop("The value of R_CONFIG_ACTIVE must not be changed in environment files",
         call. = FALSE)

  }

  # Set by Dockerfile_anomanor
  in_docker = Sys.getenv("ANOMANOR_DOCKER") == "TRUE"
  # Read from config.yml
  config = config::get(
    config = active_config,
    file = file.path(root_dir, "config.yml")
  )
  anomanor_data_base = normalizePath(config$anomanor_data_base)
  stopifnot(dir.exists(anomanor_data_base))
  data_dir = file.path(anomanor_data_base, config$data_dir)

  # This will be mapped to host in Docker for persistence
  database_dir = file.path(anomanor_data_base,
                             config$database_dir) #

  # content in these directories should not be deleted
  patients_dir = file.path(data_dir, "patients")
  md_dir = file.path(data_dir, "md")
  record_dir = file.path(data_dir, "records")


  # When directories are empty or missing, these are created and
  # files are first-time copied
  n_copied_patient = copy_from_data_store(patients_dir, if_empty_only = TRUE)
  n_copied_record = copy_from_data_store(record_dir, if_empty_only = TRUE)
  n_copied_md = copy_from_data_store(md_dir, if_empty_only = FALSE)

  # content and structure of cache dir will be restored if deleted
  cache_dir = file.path(anomanor_data_base, config$cache_dir)
  record_cache_dir = file.path(cache_dir, "records")
  png_dir = file.path(cache_dir, "png")
  html_dir = file.path(cache_dir, "html") # html cache, writable

  safe_create_dir(cache_dir) # Must be first
  safe_create_dir(data_dir)
  safe_create_dir(png_dir)
  safe_create_dir(record_cache_dir)
  safe_create_dir(html_dir)
  safe_create_dir(database_dir)

  if (str_starts(active_config, "test")  &&
      exists("copy_test_data", mode = "function")) {
    safe_create_dir(patients_dir)
    safe_create_dir(md_dir)
    gg = mget(ls())
    copy_test_data(gg) # Does nothing if not overridden
    sqlite_path = ":memory:"
  } else {
    # Database will be created if it does not exist
    # Does nothing if database exists
    # Deletes the record cache folder when a new database is created
    sqlite_path = file.path(database_dir, "anomanor.sqlite")
  }

  # Does nothing if already there
  pool = create_tables_and_pool(sqlite_path, record_cache_dir)

  if (!file_test("-d", data_dir))
    log_stop("No data directory found :", data_dir)
  if (!file_test("-d", patients_dir))
    log_stop("Patient directory does not exist :", patients_dir)
  if (length(dir(record_dir, "^.*\\.txt$")) == 0) {
    log_stop("No patient records found in ", record_dir)
  }

  # nocov start
  keycloak = NULL
  # For Admin site
  keycloak_site = glue("<a href=",
    "https://{config$keycloak_site}/admin/master/console target='_blank'>",
    "Keycloak interface</a>")

    # Force port 443 if we have a string
  assign("g", mget(ls()), envir = .GlobalEnv)
  if (config$use_keycloak && !keycloak_available())
    log_stop(
      glue(
      "Keycloak requested but not available - R_CONFIG_ACTIVE={active_config}; ",
      "keycloak_site:port in config.yml: {config$keycloak_site}:{config$keycloak_port}")
      )

  if (keycloak_available()) {
    if (active_config == "keycloak_production") {
      if (config$anomanor_admin_username == "")
        log_stop("Please set the environment variable ANOMANOR_ADMIN_USERNAME")
      if (config$anomanor_admin_password == "")
        log_stop("Please set the environment variable ANOMANOR_ADMIN_PASSWORD")
    }
    keycloak = Keycloak$new(config$anomanor_admin_username,
                           config$anomanor_admin_password,
                           config$anomanor_secret,
                           config$keycloak_site,
                           config$keycloak_port,
                            active_config)
    if (!keycloak$active()) {
      log_stop(glue(
        "Cannot get authorization from Keycloak for {config$anomanor_admin_username}"))
    }
  }
  # nocov end

  rgb_med = rev(c("#620045", "#92006D", "#C30344", "#F90401", "#FD4500",
                  "#FD9800", "#FBEA01", "#A2FC00", "#38ED12", "#01EDD2",
                  "#234CF5", "#12045B")) # Medtronic colors
  color_lookup = colorRampPalette(rgb_med)(100)
  min_p = -10 # Minimal color-coded pressure
  hrm_legend_width = 80L
  line_legend_width  = as.integer(hrm_legend_width*0.5)

  image_height = 621L # Will be checked that it is equal to effective height
  balloon_size = 40 # Not to scale, for display on upper margin only
  sensor_step = 6 # Sensors are 6 mm apart
  mm_resolution = 0.1
  time_ticks = 10 # number of seconds for a tick
  n_line_channels = 5 # Number of line channels excluding balloon
  time_zoom_levels = c(1, 2, 4)
  # For app_ui, package keys
  hotkeys <- c("esc", "left", "right", "+", "-")
  pressure_choices = c(60, 80, 100, 120, 150, 200, 300)


  # Conversion from image y coordinates to cm on sensor
  image_y_to_position_fac = sensor_step/ ((image_height - 2*balloon_size)*mm_resolution)

  classification_phase_choices =
    c( "All" = "all",
    "1. RAIR" = "rair",
    "2. Tone & contractility" = "tone",
    "3. Anorectal Coordination" = "coord")

  # Required and optional markers
  mcp = dbGetQuery(g$pool,
     "SELECT marker, classification_phase, mtype from marker_classification_phase
     order by marker")

  tippy_global_theme("translucent")

  # Requires temporary g assigned above
  assign("g", mget(ls()), envir = .GlobalEnv)
  initial_record_cache()

  # Uses package zeallot. Access as g$nodes and g$edges
  c(nodes, edges) %<-% nodes_edges(pool)

  if (active_config != "keycloak_production") {
    # Generate data set when "test..." is active
    #### Danger #####
    force_generate = FALSE # Set to true to reset on each start
    if (str_starts(active_config, "test") || force_generate) {
      test_users = c("aaron", "x_bertha", "caesar", "x_dora", "x_emil", "x_franz",
                     "x_consensus")
      gg = generate_sample_classification(test_users, force = TRUE,
                expert_complete = TRUE, add_consensus = TRUE, nodes = nodes)
      # Simulate history
      dbExecute(g$pool, "DELETE FROM history")
      simulate_backward_history(add_history_record())

      if (!str_starts(active_config, "test"))
        log_it(gg)
    }
  }
  # Write log number of copied data
  if (n_copied_patient > 0)
    log_it(
      glue("Initially copied  {n_copied_patient} sample case description files (md)"))
  if (n_copied_record > 0)
    log_it(glue(
      "Initially copied  {n_copied_record} sample case records (txt)"))
  if (n_copied_md > 0)
    log_it(glue(
      "Initially copied  {n_copied_md} static data records and images (md, txt)"))
  rm(n_copied_md, n_copied_record, n_copied_patient)
  # Write table of balloon success if it does not exist
  balloon_success = get_balloon_success(g$pool)

  assign("g", mget(ls()), envir = .GlobalEnv)
  # Check if all patients have records and reports. Returns a
  # string to display in toast on inconsistency
  cp = check_patient_records()
  log_it(paste("Startup time (s):", round((proc.time() - ptm)[3], 2)))
  cp
}
