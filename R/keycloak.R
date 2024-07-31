#nocov start
Keycloak = R6::R6Class("Keycloak", list(

  realm = "anomanor",
  groups = NULL,
  bearer = NULL,
  base_url = NULL,
  admin_url = NULL,
  headers = NULL,
  admin_username = NULL,
  admin_password = NULL,
  anomanor_secret = NULL,


  # To update bearer, see
  # https://yihui.org/en/2017/10/later-recursion/
  initialize = function(admin_username, admin_password, anomanor_secret,
                        keycloak_site, keycloak_port, active_config) {
    if (active_config == "keycloak_production") {
      if (is.null(admin_username) || admin_username == "")
        log_stop("keyloack_production: ",
                 "No user name in environment variable ADMIN_USERNAME")
      if (is.null(admin_password) || admin_password == "")
        log_stop("keyloack_production:",
                 "No password in environment variable ADMIN_PASSWORD")
    }
    if (stringr::str_starts(keycloak_site, "keycloak")) {
      self$base_url = glue("https://{keycloak_site}")
    } else {
      self$base_url = glue("http://{keycloak_site}:{keycloak_port}")
    }
    self$admin_url = glue("{self$base_url}/admin/realms/{self$realm}")
    self$admin_username = admin_username
    self$admin_password = admin_password
    self$anomanor_secret = anomanor_secret
    self$authenticate() # First login
  },

  authenticate = function(){
    # Authentication get bearer
    url = glue("{self$base_url}/realms/{self$realm}/protocol/openid-connect/token")
    # Error missing grant_type in Postman:  Must send in body, not in params
    # Error: account not fully setup: Verify email in users
    body = list(
      client_id = self$realm,
      username = self$admin_username,
      password = self$admin_password,
      client_secret = self$anomanor_secret,
      grant_type = "password"
    )
    #log_it(paste("Authentication ", url, paste(body, collapse = "\n "), sep = "\n"),
#           force_console = TRUE)

    auth_post = httr::POST(url = url, body = body, encode = "form")
    if (!self$valid_status(auth_post)) return(NULL)
    content = httr::content(auth_post)
    self$bearer = glue("Bearer {content$access_token}")

    self$headers = httr::add_headers(
      "Content-Type" = "application/json",
      "Authorization" = self$bearer
    )
    self$groups = self$get_groups()
    # use is.null(self$bearer) to test for valid
  },

  post = function(url, body, encode = 'json') {
    pst = httr::POST(url, self$headers, body = body, encode = encode)
    if (self$valid_status(pst))  return(pst)
    if (httr::status_code(pst) == 401)
      log_it("Trying to re-authenticate")
    self$authenticate()
    pst = httr::POST(url, self$headers, body = body, encode = encode)
    if (self$valid_status(pst))
      log_it("Re-authenticate success")
    pst
  },

  get = function(url) {
    gt = httr::GET(url, self$headers)
    if (self$valid_status(gt)) return(gt)
    if (httr::status_code(gt) == 401)
      log_it("Trying to re-authenticate")
    self$authenticate()
    gt = httr::GET(url, self$headers)
    if (self$valid_status(gt))
      log_it("Re-authenticate success")
    gt
  },

  delete = function(url) {
    del = httr::DELETE(url, self$headers)
    if (self$valid_status(del)) return(del)
    if (httr::status_code(del) == 401)
      log_it("Trying to re-authenticate")
    self$authenticate()
    del = httr::DELETE(url, self$headers)
    if (self$valid_status(del))
      log_it("Re-authenticate success")
    del
  },

  active = function() {
    !is.null(self$bearer) &&
      setequal(self$groups$name, c("experts", "admins", "trainees"))
  },

  add_user = function(new_user_email, group, force_confirm = TRUE,
                      emailVerified = FALSE) {
    # Add user
    new_user_name = str_extract(new_user_email, "([^@]*)")
    url = glue("{self$admin_url}/users")
    stopifnot(length(group) == 1) # Only one group allowed
    stopifnot(group %in% c("experts", "admins", "trainees"))
    body = list(email = new_user_email, username = new_user_name,
                emailVerified = emailVerified,
                enabled = TRUE, groups = list(group))
    new_user_post = self$post(url, body = body, encode = "json")
    if (self$valid_status(new_user_post)) {
      user_id = self$get_userid_from_email(new_user_email)
      if (httr::status_code(new_user_post) == 201 || force_confirm) {
        req = self$execute_actions_email(user_id)
        if (req)
          attr(user_id, "email") = "Email confirmation requested"
      }
      user_id
    } else NULL
  },

  logout_user_by_name = function(name){
    user_id = self$get_userid_from_name(name)
    if (is.null(user_id)) return(NULL)
    url = glue("{self$admin_url}/users/{user_id}/logout")
    httr::status_code(self$post(url, NULL))
  },

  get_userid_from_email = function(email) {
    # Get id of user given email
    url = glue("{self$admin_url}/users?email={email}")

    user_id_get = self$get(url)
    if (!(self$valid_status(user_id_get)))
      return(NULL)
    user_id_content = httr::content(user_id_get)
    if (length(user_id_content) == 0)
      return(NULL)
    user_id_content[[1]]$id
  },

  get_userid_from_name = function(name) {
    # Get id of user given name
    url = glue("{self$admin_url}/users?username={name}")
    user_id_get = self$get(url)
    if (!(self$valid_status(user_id_get)))
      return(NULL)
    user_id_content = httr::content(user_id_get)
    if (length(user_id_content) == 0)
      return(NULL)
    user_id_content[[1]]$id
  },

  execute_actions_email = function(user_id)  {
    # Request update account
    url = glue("{self$admin_url}/users/{user_id}/execute-actions-email")
    actions_email = httr::PUT(
      url,
      self$headers,
      body = '["UPDATE_PASSWORD"]',
      encode = "raw"
    )
    httr::status_code(actions_email) == 204
  },

  delete_user = function(email) {
    user_id = self$get_userid_from_email(email)
    if (is.null(user_id)) return(NULL)
    url = glue("{self$admin_url}/users/{user_id}")
    del = self$delete(url)
    httr::status_code(del) == 204
  },

  get_groups = function() {
    url = glue("{self$admin_url}/groups")
    groups = self$get(url)
    if (!(self$valid_status(groups)))
      return(NULL)
    groups %>% httr::content() %>% { tibble(
      id = map_chr(., "id"),
      name = map_chr(., "name")
    )}
  },

  userId_from_name = function(user_id_or_name){
    # Allow for names or userID here
    is_userId =
      str_detect(str_replace_all(user_id_or_name, "-", ""), "[0-9a-f]{32}")
    if (is_userId) {
      user_id_or_name
    } else {
      self$get_userid_from_name(user_id_or_name)
    }
  },

  user_groups = function(user_id_or_name) {
    user_id = self$userId_from_name(user_id_or_name)
    if (is.null(user_id))
      return(NULL)
    url = glue("{self$admin_url}/users/{user_id}/groups")
    groups = self$get(url)
    if (!self$valid_status(groups))
      return(NULL)
    gr = groups %>% httr::content() %>% { tibble(
      id = map_chr(., "id"),
      name = map_chr(., "name"),
    )}
    # Prioritize groups, only return one
    gr1 = gr %>% filter(name == 'admins')
    if (nrow(gr1) == 0)
      gr1 = gr %>% filter(name == 'experts')
    if (nrow(gr1) == 0)
      gr1 = gr
    gr1
  },

  group_members = function(groupId){
    url = glue("{self$admin_url}/groups/{groupId}/members")
    users = self$get(url)
    if (!self$valid_status(users))
      return(NULL)
    users %>% httr::content() %>% { tibble(
      groupId = groupId,
      id = map_chr(., "id"),
      username = map_chr(., "username", .default = NA),
    )}
  },

  all_group_members = function(){
    map_dfr(self$groups$id, self$group_members ) %>%
      left_join(self$groups, by = c("groupId" = "id"))
  },

  users = function() {
    url = glue("{self$admin_url}/users")
    users = self$get(url)
    if (!self$valid_status(users)) {
      return(NULL)
    }
    users = users %>% httr::content() %>% { tibble(
      id = map_chr(., "id"),
      username = map_chr(., "username", .default = NA),
      email = map_chr(., "email", .default = NA),
      firstName = map_chr(., "firstName", .default = NA),
      lastName = map_chr(., "lastName", .default = NA),
      group = pluck(., "attributes", "group"),
      emailVerified = map_lgl(., "emailVerified"),
      enabled = map_lgl(., "enabled")
    )}
    ag = self$all_group_members()
    ag = ag %>% select(id, name) %>% group_by(id) %>%
      summarize(experts = "experts" %in% name,
                admins = "admins" %in% name,
                trainees = "trainees" %in% name)
    users %>%  left_join(ag, by = "id") %>%
      mutate(
        experts = replace_na(experts, FALSE),
        admins = replace_na(admins, FALSE),
        trainees = replace_na(trainees, FALSE)
      )
  },

  valid_status = function(ret){
    httr::status_code(ret) %in% c(200, 201, 204)
  }
))
#nocov end
