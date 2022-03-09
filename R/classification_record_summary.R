classification_record_summary = function(user, method) {
  q = glue_sql("SELECT r.record, r.anon_h, r.anon_l, sum(c.finalized) as nfinalized ",
  "from record r LEFT JOIN (SELECT record, finalized from classification c ",
  "where user = {user} and method = {method}) as c ",
  "on r.record = c.record where r.valid = 1 ",
  "group by r.record order by r.record", .con = g$pool)
  dbGetQuery(g$pool, q) %>%
    mutate(
      icon = case_when(
        is.na(nfinalized) ~ "fa-question",
        nfinalized == 0 ~ "fa-battery-1",
        nfinalized == 1 ~ "fa-battery-2",
        nfinalized == 2 ~ "fa-battery-3",
        nfinalized == 3 ~ "fa-flag-checkered"
      ),
      anon = case_when(
        method == 'h' ~ anon_h,
        method == 'l' ~ anon_l,
        TRUE ~ "xxx"),
      anon_l = NULL,
      anon_h = NULL
    ) %>%
    arrange(.data$anon) %>%
    as_tibble()
}

