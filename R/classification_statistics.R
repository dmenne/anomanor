classification_statistics = function(use_group = "all", method = "h" ) {
  stopifnot(is.list(g)) # requires global
  # groups: all, experts, trainees
  stopifnot(use_group %in% c("all", "experts", "trainees"))
  # If keycloak is not available gets users from table user
  users = keycloak_users()
  if (is.null(users)) # Something went wrong
    return(NULL)
  # This code could be made more efficient by filtering on required
  # users earlier
  users_f = users %>%
    filter(group !=  "admins") %>%
    filter(verified) %>%
    select(user, group)
  if (use_group != "all") {
    users_f = users_f %>%
    filter(group == use_group)
  }

  # Database
  q = glue_sql("SELECT record, method, user, classification_phase as phase,
               classification ",
               "FROM classification where finalized = 1 ",
               "and method = {method}", .con = g$pool)
  # nodes are package-internal data
  nodes_short = nodes %>%
    filter(group != "a") %>%
    select(phase, id, short)
  dbGetQuery(g$pool, q) %>%
    select(-method) %>%
    left_join(users_f, by = "user") %>%
    filter(!is.na(group)) %>%
    group_by(record, group, phase, classification) %>%
    summarize(
      n = n(),
      .groups = "drop"
    ) %>%
    left_join(nodes_short,
      by = c("phase" = "phase", "classification" = "id"))
}

classification_statistics_wide = function(use_group = "all",
                            method = 'h',
                            classification_name = "short") {
  stopifnot(classification_name %in% c("short", "classification"))
  stopifnot(method %in% c("h", "l"))
  cs = classification_statistics(use_group = use_group, method = method)
  . = NULL
  map(
    set_names(c("rair", "tone", "coord")), function(.x){
      cs  %>%
      filter(phase == .x) %>%
      pivot_wider(
        id_cols = c("record"),
        names_from = c(all_of(classification_name), "group"),
        values_from = "n"
      ) %>%
      replace(is.na(.), 0) %>%
      mutate(
        sum_trainees = rowSums(select(., ends_with("_trainees"))),
        sum_experts = rowSums(select(., ends_with("_experts")))
      ) %>%
      select(record, sort(colnames(.)))
    }
  )
}

alpha_text = function(alpha, classification_phase_sel){
  ap_c = alpha %>%
    filter(classification_phase == classification_phase_sel)
  if (nrow(ap_c) == 0) return(" not calculated")
  alpha_ret = "from"
  ex = ap_c %>%
    filter(group == "experts")
  if (nrow(ex) == 1 )
    alpha_ret = glue("from {ex$n_raters} expert raters, \u3B1={ex$estimate}, ",
                     "CI 95% ({ex$lower} to {ex$upper}); " )
  tr = ap_c %>% filter(group == "trainees")
  if (nrow(tr) == 1 )
    alpha_ret = glue(
     "{alpha_ret} from {tr$n_raters} trainee raters, \u3B1={tr$estimate}, ",
     "CI 95% ({tr$lower} to {tr$upper})")
  alpha_ret
}

