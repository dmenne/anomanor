kripp = function(x) {
  if (nrow(x) == 0) return(tibble())
  dt = as.matrix(x)
  kr = icr::krippalpha(dt, metric = "nominal", bootstrap = TRUE, nboot = 4000)
  ci = quantile(kr$bootstraps, c(0.025, 0.975), na.rm = TRUE)
  tibble(
    estimate = round(kr$alpha,2),
    lower = round(ci[1], 2),
    upper = round(ci[2], 2),
    n_raters = kr$n_coders
  )
}

krippendorff_alpha = function(method) {
  q = glue_sql("SELECT * from krippendorff where method ={method}", .con = g$pool)
  dbGetQuery(g$pool, q)  %>%
    select(-method) %>%
    group_by(.data$classification_phase, .data$group) %>%
    transmute(
      user = as.integer(as.factor(.data$user)),
      record = as.integer(as.factor(.data$record)),
      classification = .data$classification
    ) %>%
    pivot_wider(id_cols = c("user", "classification_phase", "group"),
                names_from = "record",
                values_from = .data$classification,
                values_fill = NA, names_repair = "minimal") %>%
   select(-.data$user) %>%
   group_modify(~kripp(.x))
}

