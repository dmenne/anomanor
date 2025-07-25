hrm_legend = function(max_p) {
  stopifnot(is.list(g))
  legend_file = legend_file_name(max_p)
  if (file.exists(legend_file))
    return(legend_file)
  png(legend_file, width = g$hrm_legend_width, height = g$image_height)
  par(mar = rep(0, 4))

  balloon_width = 0.28
  balloon_height =  g$balloon_size/g$image_height
  cath_width = 0.06
  balloon_left = 0.7
  cath_left = balloon_left + (balloon_width - cath_width)/2
  fill = "#FFD5C7" # from medtronic
  border = "#CCAA9F"
  plot_width = 1.4

  plot(0, xlim = c(0, plot_width), ylim = c(0, 1), type = "n",
       frame.plot = FALSE, axes = FALSE)
  corrplot::colorlegend(
    g$color_lookup,
    seq(g$min_p, max_p, by = 10),
    align = "c"
  )

  grid::grid.roundrect(
    x = balloon_left,
    y = 1,
    r = grid::unit(0.5, "snpc"),
    just = c("left", "top"),
    width = balloon_width,
    height = balloon_height,
    gp = grid::gpar(fill = fill, col = border, lwd = 2)
  )
  grid::grid.rect(
    x = cath_left,
    y = 1 - balloon_height,
    just = c("left", "top"),
    width = cath_width,
    height = balloon_height*1.3,
    gp = grid::gpar(fill = "gray", col = border, lwd = 2  )
  )
  grid::grid.rect(
    x = cath_left,
    y = 0.99 - 2*balloon_height,
    just = c("left", "top"),
    width = cath_width,
    height = 1,
    gp = grid::gpar(fill = fill, col = border, lwd = 2 )
  )
  sensors = seq(0, 1, length.out = 10)* (1.0 - 2*balloon_height)
  lapply(sensors, function(x) {
    grid::grid.lines(c(cath_left + cath_width, plot_width), c(x, x),
               gp = grid::gpar(lwd = 3, col = border))
    }
  )
  dev.off()
  legend_file
}
