# This is file globals(sic!).R, not Shiny special global.R
# Variables in this function are can be accessed via g$,
# as defined in run_app.R
utils::globalVariables("g")
globals = function(){
#  options(warn = 2)
#  options(shiny.error = browser)


  # Default configuration must set globally
  # By default, user is sa_admin
  active_config = Sys.getenv("R_CONFIG_ACTIVE", "sa_admin")

  # See valid values in config.yml
  valid_config = c("sa_trainee", "sa_admin", "sa_expert", "test",
                   "test_expert", "keycloak_devel",
                   "keycloak_production", "sa_random_trainee" )
  if (!active_config %in% valid_config)
    stop("Please set environment variable R_CONFIG_ACTIVE, ",
         "currently '", active_config, "' to one of ",
         paste(valid_config, collapse = ", "),call. = FALSE)
  # Renviron_production is not saved in git
  env_file_base =  case_when(
      Sys.info()['sysname'] == 'Windows' ~ "Renviron_windows",
      active_config == "keycloak_production" ~ "Renviron_production",
      TRUE ~ "Renviron_devel")
  root_dir = app_sys()
  env_file = file.path(root_dir, env_file_base)
  if (!file.exists(env_file))
    stop("Environment file ", env_file, " does not exist", call. = FALSE)
  readRenviron(env_file)
  if (Sys.getenv("R_CONFIG_ACTIVE") != active_config)
    stop("The value of R_CONFIG_ACTIVE must not be changed in environment files",
         call. = FALSE)

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
  safe_create_dir(patients_dir)
  safe_create_dir(md_dir)
  safe_create_dir(record_dir)

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
  }

  # Database will be created if it does not exist
  # Does nothing if database exists
  # Deletes the record cache folder when a new database is created
  sqlite_path = file.path(database_dir, "anomanor.sqlite")
  # Does nothing if already there
  pool = create_tables_and_pool(sqlite_path, record_cache_dir)

  if (!file_test("-d", data_dir))
    log_stop("No data directory found :", data_dir)
  if (!file_test("-d", patients_dir))
    log_stop("Patient directory does not exist :", patients_dir)
  if (length(dir(record_dir, "^.*\\.txt$")) == 0) {
    log_stop("No patient records found in ", record_dir)
  }


  keycloak = NULL
  # For Admin site
  keycloak_site = glue("<a href=",
    "https://{config$keycloak_site}/auth/admin/anomanor/console target='_blank'>",
    "Keycloak interface</a>")

  # Force port 443 if we have a string
  g <<- mget(ls()) # Temporary global
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
                           config$keycloak_site,
                           config$keycloak_port,
                            active_config)
    if (!keycloak$active()) {
      log_stop(glue(
        "Cannot get authorization from Keycloak for {config$anomanor_admin_username}"))
    }
  }

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
  time_zoom_levels = c(1,2,4)
  # For app_ui, package keys
  hotkeys <- c("esc", "left", "right", "+", "-")
  pressure_choices = c(60, 80, 100, 120, 150, 200, 300)


  # Conversion from image y coordinates to cm on sensor
  image_y_to_position_fac = sensor_step/((image_height - 2*balloon_size)*mm_resolution)

  classification_phase_choices =
    c("All" = "all",
    "1. RAIR" = "rair",
    "2. Tone & contractility" = "tone",
    "3. Anorectal Coordination" = "coord")

  # Required and optional markers
  mcp = dbGetQuery(g$pool,
     "SELECT marker, classification_phase, mtype from marker_classification_phase order by marker")

  krip_text = HTML("Krippendorff's &alpha; <ul><li>&alpha; =1 indicates perfect inter-rater reliability</li><li>&alpha; =0 indicates the absence of inter-rater reliability. Units and the values assigned to them are statistically unrelated.</li><li>&alpha; &#60; 0 when disagreements are systematic and exceed what can be expected by chance.</li></ul>95% confidence intervals (CI 95%) were calculated using the bootstrap.")

  tippy_global_theme("translucent")

  # Requires temporary g assigned above
  g <<- mget(ls()) # Temporary replacement for global g
  initial_record_cache()


  test_users = c("aaron", "x_bertha", "caesar", "x_dora", "x_emil", "x_franz")
  # Generate data set when "test..." is active
  force_generate = FALSE # Set to true to reset on each start
  if (str_starts(active_config, "test") || force_generate) {
    gg = generate_sample_classification(test_users, force = TRUE,
                                        expert_complete = TRUE, add_consensus = TRUE)
    if (!str_starts(active_config, "test"))
      log_it(gg)
  }

  # Check if all patients have records and reports. Returns a
  # string to display in toast on inconsistency
  checked_patients = check_patient_records()
  mget(ls())
}
