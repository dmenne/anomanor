# ---- plot_time (horizontal section) ------------------------
plot_time = function(xy, max_p) {
  # Degenerate case
  xy_sensor = xy[xy$where == "sensor", ]
  req(nrow(xy_sensor) > 0 )
  req(any(xy_sensor$press != 0))
  # Compute baseline
  tree = rpart::rpart(press ~ time, data = xy_sensor)
  pred = predict(tree,
      data.frame(time = min(xy_sensor$time):max(xy_sensor$time)))
  baseline = min(rle(pred)$values)

  # Plotting
  par(mar = c(4, 3.5, .5, .5))
  ylim = c(0, max_p) # fixed scale

  plot(xy_sensor$time, xy_sensor$press, ylab = "", xlab = "",
    type = "l", bty = "n", ylim = ylim)
  title(ylab = "p (mmHg)",  xlab = "time(s)", mgp = c(2.2, 2, 2))

  xy_fill = xy_sensor[xy_sensor$press > baseline, ]
  max_time = max(xy_fill$time)
  polygon(c(xy_fill$time, max_time, 0),
          c(xy_fill$press, baseline, baseline),
          col = "#D6E3FF")
  arrow_x = which.max(xy_sensor$press)
  arrow_loc = xy_sensor$time[arrow_x]
  peak = xy_sensor$press[arrow_x]
  arrows(arrow_loc, baseline, arrow_loc, peak, code = 3,
    length = 0.2, angle = 20, col = "red")
  text(arrow_loc, (peak + baseline) / 2,
       labels = paste(round(peak - baseline), "mmHg"), adj = 0.)
  abline(h = 0, col = "lightgray")
  abline(h = peak, col = "lightgray")
  # Return data for display
  ddd = xy_fill
  ddd$press = ddd$press - baseline
  # Return results
  section_data(xy, peak - baseline)
}

# ---- plot_position (vertical section) ------------------------
plot_position = function(xy, max_p) {
  stopifnot(is.list(g)) # requires globals
  xy_sensor = xy[xy$where == "sensor", ]
  if (nrow(xy_sensor) == 0) return(NULL)
  xy_sensor$pos = xy_sensor$pos - min(xy_sensor$pos)
  req(nrow(xy_sensor) > 0 )
  # Use simple minimum as baseline
  baseline = min(xy_sensor$press)
  # Plotting
  par(mar = c(4, 3.5, .5, .5))
  balloon_press = attr(xy, "balloon_press")
  ylim = range(xy_sensor$pos)
  balloon_width = ylim[2]/5
  ylim[2] = ylim[2] + balloon_width
  xy_sensor$press = rev(xy_sensor$press)
  xlim = c(0, max_p) # fixed scale
  #xlim = range(xy_sensor$press)
  #xlim[2] = max(xlim[2], balloon_press)
  plot(xy_sensor$press,  xy_sensor$pos, ylim = ylim,  xlim = xlim,
       xlab = "",  ylab = "", type = "l", bty = "n")
  title(ylab = "sensor position (mm)",  xlab = "p (mmHg)", mgp = c(2.2, 2, 2))
  balloon_press = attr(xy, "balloon_press")
  balloon_color = g$color_lookup[
    (min(max(balloon_press, g$min_p), max_p) - g$min_p)*100/ (max_p - g$min_p)]
  yrect = ylim[2] - (ylim[2] - ylim[1])*.1
  rect(0, yrect, balloon_press, ylim[2], col = balloon_color)
  text(xlim[1], yrect, glue("balloon {balloon_press} mmHg"), adj = c(0, -.7))
  xy_fill = rev(xy_sensor[xy_sensor$press > baseline, ])
  max_pos = max(xy_fill$pos)
  polygon(c(baseline, xy_fill$press, baseline),
          c(0, xy_fill$pos, max_pos), col = "#D6E3FF")
  abline(v = balloon_press, lty = 3, col = balloon_color)
  arrow_x = which.max(xy_sensor$press)
  arrow_pos = xy_sensor$pos[arrow_x]
  peak = xy_sensor$press[arrow_x]
  arrows(baseline, arrow_pos, peak, arrow_pos, code = 3, length = 0.2,
    angle = 20, col = "red" )
  text((peak + baseline) / 2, arrow_pos, pos = 3,
       labels = paste(round(peak - baseline), "mmHg"))
  abline(v = peak, col = "lightgray")
  abline(v = 0, col = "lightgray")
  # Return results
  section_data(xy, peak - baseline)
}

# -------------------------------- section_data -------------------------------------
section_data = function(xy_sensor, above_base) {
  dt = data.frame(name = c("duration", "length", "p min", "p max", "above base",
                      "t1", "t2", "pos1", "pos2"),
             value = with(xy_sensor, c(
               max(time) - min(time),
               max(pos) - min(pos),
               min(press),
               max(press),
               above_base,
               min(time),
               max(time),
               min(pos),
               max(pos)
             )),
             unit = c("s", "mm", "mmHg", "mmHg", "mmHg", "s", "s", "mm", "mm")
  )
  dt$value = round(dt$value, 1)
  dt
}
