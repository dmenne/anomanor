# this test is by default deactivated because it needs a working
# keycloak site
Sys.setenv("R_CONFIG_ACTIVE" = "keycloak_devel")
active_config = Sys.getenv("R_CONFIG_ACTIVE")
skip_if_not(stringr::str_starts(active_config, "keycloak_"), "Keycloak not available")
g = try(globals(), silent = TRUE)
ano_poolClose() # DB not used, avoid leakages

if (inherits(g, "try-error"))
  if (stringr::str_detect(as.character(g), "not available")) {
    skip("Keycloak not available")
  } else {
    stop(g)
  }


skip_if_not(g$config$use_keycloak,
            "Skipped because use_keycloak is FALSE in config.yml")
skip_if_not(keycloak_available())

test_that("Can connect to keycloak, add and delete users", {
  keycloak = Keycloak$new(g$config$anomanor_admin_username,
                          g$config$anomanor_admin_password,
                          "localhost",
                          g$config$keycloak_port, active_config)
  skip_if_not(keycloak$active())
  ret = keycloak$delete_user("anton@menne-biomed.de") # Just in case
  ret = keycloak$add_user("anton@menne-biomed.de", "experts")

  expect_false(is.null(keycloak$get_userid_from_email("anton@menne-biomed.de")))
  expect_true(keycloak$delete_user("anton@menne-biomed.de"))
  expect_null(keycloak$delete_user("anton@menne-biomed.de"))
  gm = keycloak$all_group_members()
  expect_equal(names(gm), c("groupId", "id", "username", "name"))
  expect_true("anomanor_admin" %in% gm$username)
  ug = keycloak$user_groups("anomanor_admin")
  expect_equal(names(ug), c("id", "name"))
  expect_equal(ug$name, "admins")
  users = keycloak$users()
  expect_equal(names(users),
        c('id','username','email','firstName','lastName',
          'emailVerified','enabled','experts','admins','trainees'))
  expect_gte(nrow(users), 1)

  # Logout
  logout = keycloak$logout_user_by_name(g$config$anomanor_admin_username)
  expect_equal(logout, 204)
})

