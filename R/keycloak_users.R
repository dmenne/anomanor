keycloak_users = function(){
  # Without keycloak, get user surrogate from database
  if (is.null(g$keycloak) || !keycloak_available() || !g$keycloak$active()) {
    q = glue_sql("SELECT user, [group] from user", .con = g$pool)
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
  if (is.null(users)) {
    log_stop("Keycloak did not return users")
    return(NULL)
  }
  # We prioritize groups, only the dominant is kept
  users = g$keycloak$users() %>%
    mutate(
      group = case_when(
        admins ~ 'admins',
        experts ~ 'experts',
        TRUE ~ 'trainees'
      )
    )
  users %>%
    transmute(
      user = username,
      email = email,
      name = ifelse(is.na(firstName) | is.na(lastName),
                     "", paste(firstName, lastName)),
      verified = emailVerified,
      group = group
    )
  # nocov end

}
