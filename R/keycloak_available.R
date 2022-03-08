keycloak_available = function(){
  stopifnot(exists("g") && is.list(g)) # globals
  if (!g$config$use_keycloak) return(FALSE)
  if (stringr::str_starts(g$config$keycloak_site, "keycloak"))
    g$config$keycloak_port = 443
  !is.na(pingr::ping_port(g$config$keycloak_site, g$config$keycloak_port,
                          count = 1, timeout = 0.1))
}

