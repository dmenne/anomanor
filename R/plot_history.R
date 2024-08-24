plot_history = function() {
  sql = glue(
    "select history_date, u.user, method, finalized, cnt from history h ",
    "left join user u on u.user = h.user ",
    "where `group` != 'admins'"
    )
  hist_stat = dbGetQuery(g$pool, sql)   |>
    mutate(
      finalized = factor(1 - finalized, labels = c("finalized", "saved" )),
      history_date = as.Date(history_date)
    )

  ggplot(hist_stat,
         aes(x = history_date,
             y = cnt,
             linetype = finalized,
             color = method,
             group = interaction(method, finalized))) +
    geom_line() +
    geom_point(alpha = 0.5, aes(shape = method)) +
    scale_x_date(guide = guide_axis(check.overlap = TRUE)) +
    facet_wrap(~user) +
    ylab("Ratings of all users over time") +
    xlab("Number of all users' ratings")

}
