create_tables = list(
"PRAGMA foreign_keys=on;",

"CREATE TABLE IF NOT EXISTS record (
  record CHAR PRIMARY KEY NOT NULL,
  anon_h CHAR (4) NOT NULL UNIQUE,
  anon_l CHAR (4) NOT NULL UNIQUE,
  file_mtime   INTEGER,
  timestep    NUMERIC NOT NULL,
  valid      BOOLEAN DEFAULT (TRUE)
);",

"CREATE TABLE IF NOT EXISTS marker (
  record     CHAR    NOT NULL
   REFERENCES record (record) ON DELETE CASCADE,
  sec        NUMERIC NOT NULL,
  indx      INTEGER NOT NULL,
  annotation CHAR,
  show        BOOLEAN DEFAULT (TRUE)
);",

"CREATE UNIQUE INDEX IF NOT EXISTS recordname_indx ON marker (
  record,
  indx
);",


"CREATE TABLE IF NOT EXISTS user (
  user    CHAR    PRIMARY KEY  NOT NULL,
  [group]   CHAR    DEFAULT 'trainees'
);",

"CREATE TABLE IF NOT EXISTS classification (
  user           CHAR    REFERENCES user (user) ON DELETE CASCADE
  ON UPDATE CASCADE
  NOT NULL,
  record         CHAR  REFERENCES record (record) ON DELETE CASCADE
  ON UPDATE CASCADE
  NOT NULL,
  method         CHAR (1) NOT NULL,
  finalized      BOOLEAN NOT NULL DEFAULT FALSE,
  protocol_phase CHAR    NOT NULL,
  classification_phase CHAR NOT NULL,
  classification INTEGER NOT NULL,
  duration       DOUBLE,
  length         DOUBLE,
  p_min          DOUBLE,
  p_max          DOUBLE,
  above_base     DOUBLE,
  t1             DOUBLE,
  t2             DOUBLE,
  pos1           DOUBLE,
  pos2           DOUBLE,
  comment        CHAR,
  timestamp      INTEGER
);",

"CREATE UNIQUE INDEX IF NOT EXISTS user_phase ON classification (
  user,
  record,
  classification_phase,
  method
);",


"CREATE TABLE IF NOT EXISTS ano_logs(
  time DATETIME NOT NULL,
  severity CHAR NOT NULL,
  message  CHAR NOT NULL
);",

"CREATE VIEW IF NOT EXISTS anon AS
SELECT record,
anon_h AS anon,
'h' AS method
FROM record
WHERE anon NOT LIKE '$ex%'
UNION
SELECT record,
anon_l AS anon,
'l' AS method
FROM record
WHERE anon NOT LIKE '$ex%';
",

"CREATE VIEW IF NOT EXISTS section AS
  SELECT record,
         classification_phase,
         protocol_phase,
         classification,
         t1,
         t2,
         pos1,
         pos2,
         user
  FROM classification
  WHERE t1 IS NOT NULL AND
        finalized = 1
  ORDER BY record,
           classification_phase,
           protocol_phase,
           user;
",

"CREATE TABLE IF NOT EXISTS marker_classification_phase (
  marker               CHAR PRIMARY KEY,
  classification_phase CHAR,
  mtype CHAR(1)
);",

"INSERT INTO marker_classification_phase (mtype, classification_phase, marker)
VALUES
('o',NULL,'Cough'),
('o',NULL,'Cough 1'),
('o',NULL,'Cough 2'),
('o',NULL,'Cough 3'),
('r','coord','Push 1'),
('r','coord','Push 2'),
('n','coord','Push 3'),
('r','rair','RAIR'),
('o',NULL,'Rectal sensory high'),
('o',NULL,'Rectal sensory low'),
('n','tone','Rest'),
('n','tone','Long Squeeze'),
('r','tone','Squeeze 1'),
('r','tone','Squeeze 2');
",

"CREATE TABLE IF NOT EXISTS history (
    history_date TEXT    NOT NULL,
    user         TEXT    NOT NULL,
    method       TEXT    NOT NULL,
    finalized    INTEGER NOT NULL,
    cnt          INTEGER NOT NULL
);
",

"CREATE UNIQUE INDEX IF NOT EXISTS unique_history ON history (
    history_date,
    user,
    method,
    finalized
);
"
)

create_pool = function(sqlite_path) {
  ret = pool::dbPool(drv = RSQLite::SQLite(), dbname = sqlite_path,
            validateQuery = "SELECT name FROM sqlite_master")
  if (!database_exists(sqlite_path))
    log_stop(glue("Creating  pool, database file {sqlite_path} does not exist"))
  if (!ret$valid) {
    log_stop("Database pool could not be created")
  } else {
    dbExecute(ret, "PRAGMA foreign_keys=ON")
  }
  ret
}

database_exists = function(sqlite_path) {
  sqlite_path == ":memory:" || file.exists(sqlite_path)
}

ano_pool_close = function() {
  # Avoid warning by checking
  if (
      exists("g") &&
      !inherits(g, "try-error") &&
      !is.null(g$pool) &&
      DBI::dbIsValid(g$pool)) {
    pool::poolClose(g$pool)
  }
}

create_tables_and_pool  = function(sqlite_path, record_cache_dir) {
  if (sqlite_path != ":memory:") {
    if (database_exists(sqlite_path)) {
      if (file.info(sqlite_path)$size == 0) {
        unlink(sqlite_path, force = TRUE)
      } else {
      # Check if tables valid
      pool_temp = create_pool(sqlite_path)
      q =
      "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
      available_tables = dbGetQuery(pool_temp, q)$name
      ano_pool_close()
      required_tables = c("ano_logs", "classification", "history", "marker",
                          "marker_classification_phase", "record", "user")
      if (length(available_tables) > 0 &&
          length(setdiff(required_tables, available_tables)) == 0)
        return(pool_temp)
      # if tables are incomplete, restart
      pool::poolClose(pool_temp)
      cat(glue("Database incomplete, recreated as ",
                  "{file_path_as_absolute(sqlite_path)}\n"))
      unlink(sqlite_path, force = TRUE)
      }
    }
}

  # Delete all cached files when the database is created
  unlink(glue("{record_cache_dir}/*.rds"))
  stopifnot(dir.exists(record_cache_dir))

  # Check database for existing tables
  sqlite_dir = dirname(sqlite_path)
  safe_create_dir(sqlite_dir)
  # create_tables is a vector of SQL statements
  pool = create_pool(sqlite_path)

  if (!database_exists(sqlite_path))
    log_stop(glue("Could not create database file {sqlite_path}"))
  lapply(create_tables, function(x) {
    dbExecute(pool, x)
    invisible(NULL)
  })
  q = "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
  table_names = dbGetQuery(pool, q)$name
  res = paste("Available database tables ", paste(table_names, collapse = ", "))
  log_it(res)
  pool
}
