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
    filter(.data$group !=  "admins") %>%
    filter(.data$verified) %>%
    select(.data$user, .data$group)
  if (use_group != "all") {
    users_f = users_f %>%
    filter(.data$group == use_group)
  }

  # Database
  q = glue_sql("SELECT record, method, user, classification_phase as phase,
               classification ",
               "FROM classification where finalized = 1 ",
               "and method = {method}", .con = g$pool)
  # nodes are package-internal data
  nodes_short = nodes %>%
    filter(.data$group != "a") %>%
    select(.data$phase, .data$id, .data$short)
  dbGetQuery(g$pool, q) %>%
    select(-.data$method) %>%
    left_join(users_f, by = "user") %>%
    filter(!is.na(.data$group)) %>%
    group_by(.data$record, .data$group, .data$phase, .data$classification) %>%
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
      filter(.data$phase == .x) %>%
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
      select(.data$record, sort(colnames(.)))
    }
  )
}

alpha_text = function(alpha, classification_phase_sel){
  ap_c = alpha %>%
    filter(.data$classification_phase == classification_phase_sel)
  if (nrow(ap_c) == 0) return(" not calculated")
  alpha_ret = "from"
  ex = ap_c %>%
    filter(.data$group == "experts")
  if (nrow(ex) == 1 )
    alpha_ret = glue("from {ex$n_raters} expert raters, \u3B1={ex$estimate}, ",
                     "CI 95% ({ex$lower} to {ex$upper}); " )
  tr = ap_c %>% filter(.data$group == "trainees")
  if (nrow(tr) == 1 )
    alpha_ret = glue(
     "{alpha_ret} from {tr$n_raters} trainee raters, \u3B1={tr$estimate}, ",
     "CI 95% ({tr$lower} to {tr$upper})")
  alpha_ret
}

classification_statistics_html = function(method) {
  cs_w = classification_statistics_wide(method = method)
  alpha = krippendorff_alpha(method = method)

  bg_f = function(sum_col, cs1) {
    cols = cs1[[sum_col]]
    function(i) {
      if (all(cols == 0)) return("gray95")
      map2_chr(i, cols , function(x, y){
        scales::col_numeric(c("transparent", '#99CCFF'), domain = c(0, y ))(x)
      })
    }
  }

  map2(cs_w, names(cs_w), function(cs1, phase){
    if (nrow(cs1) == 0) return(NULL)
    cn = str_split_fixed(colnames(cs1), "_", 2)
    rle_cn = rle(cn[, 1])
    phase_text =
      names(g$classification_phase_choices)[g$classification_phase_choices == phase]
    ccc = cs1 %>%
      flextable() %>%
      set_header_labels(values = setNames(cn[,2], colnames(cs1)))   %>%
      add_header_row(values = rle_cn$values, colwidths = rle_cn$lengths) %>%
      set_table_properties(layout = "autofit") %>%
      set_caption(glue("Classification phase {phase_text}."),
                  style = "classification_caption")   %>%
      add_footer(record = HTML(glue("Krippendorff's \u3B1 ",
                       "{alpha_text(alpha, phase)}. ",
          "Background colors code for relative frequency in user group"))) %>%
      merge_at(j = 1:ncol(cs1), part = "footer")
    ccc = ccc %>%
     flextable::bg(
       bg = bg_f("sum_trainees", cs1),
       j =  which(cn[, 2] == "trainees")
      )
    ccc = ccc %>%
      flextable::bg(
        bg = bg_f("sum_experts", cs1),
        j = which(cn[, 2] == "experts")
      )
  })
}
