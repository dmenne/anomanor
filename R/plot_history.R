plot_history = function() {
  sql = glue(
    "select history_date, u.user, method, finalized, cnt from history h ",
    "left join user u on u.user = h.user ",
    "where `group` != 'admins'"
    )
  hist_stat = dbGetQuery(g$pool, sql) |>
    mutate(
      finalized = factor(1-finalized, labels = c("finalized", "saved" ))
    )

  ggplot(hist_stat,
         aes(x = as.POSIXct(history_date),
             y = cnt,
             color = method,
             group = method)) +
    geom_line() +
    geom_jitter(alpha = 0.5, aes(shape = method)) +
    #scale_x_date(guide = guide_axis(check.overlap = TRUE)) +
    facet_wrap(~user) +
    xlab("Finalized ratings") +
    ylab("Date of backup")
}
