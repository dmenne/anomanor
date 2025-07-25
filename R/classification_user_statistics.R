classification_user_query = function() {
  glue("
    SELECT user, method, finalized, count(finalized) as n
    FROM classification c
    LEFT JOIN record r
    ON c.record = r.record
    where r.anon_l not like '$%' and r.anon_h not like '$%'
    GROUP By user, method, finalized
  ")

}
classification_user_statistics = function() {
  q = classification_user_query()
  stat = dbGetQuery(g$pool, q)  %>%
    mutate(
      state = ifelse(finalized == 0, "saved", "finalized"),
      finalized = NULL
      #method = if_else(method == "l", "Line", "HRM")
    ) %>%
    pivot_wider(id_cols = c("user", "method"),
                names_from = "state", values_from = n)
  if (nrow(stat) == 0) return(NULL)
  users = keycloak_users()  # NULL if no keycloak
  if (!is.null(users))
    stat = users %>%
      left_join(stat, by = "user")
  stat  %>%
    replace_na(list(saved = 0, finalized = 0)) %>%
  as_tibble()
}
