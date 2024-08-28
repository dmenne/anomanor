plot_history = function() {
  sql = glue(
    "select history_date, u.user, method, finalized, cnt from history h ",
    "left join user u on u.user = h.user ",
    "where `group` != 'admins'"
    )
  hist_stat = dbGetQuery(g$pool, sql)
  max_history_date = str_replace(max(hist_stat$history_date), "T", " ")
  hist_stat = hist_stat |>
    mutate(
      finalized = if_else(finalized == 1, "finalized", "saved" ),
      history_date = as.Date(history_date),
    )
  if (nrow(hist_stat) == 0) return(NULL)
  ggplot(hist_stat,
         aes(x = history_date,
             y = cnt,
             linetype = finalized,
             color = method,
             group = interaction(method, finalized))) +
    geom_line() +
    geom_point(alpha = 0.5, aes(shape = method)) +
    scale_x_date(guide = guide_axis(check.overlap = TRUE)) +
    facet_wrap(~user, ncol = 5) +
    ylab("Number of ratings") +
    xlab("Date") +
    ggtitle(glue("History - last updated {max_history_date}"))
}

