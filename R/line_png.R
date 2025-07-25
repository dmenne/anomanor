line_png = function(ss, png_line_file, max_p, time_step_stretched) {
  stopifnot(is.list(g)) # requires globals
  channels = line_channels()
  sct = ss[, channels]
  offset_step = round(g$image_height/ (g$n_line_channels + 1))
  scale = offset_step/max_p
  png(png_line_file, width = nrow(sct), height = g$image_height)
  par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
  plot.new()
  plot.window(xlim = c(0, nrow(sct)), ylim = c(0, g$image_height))
  offsets = rev(as.integer(seq(0, g$image_height, by = offset_step)))
  stopifnot(length(offsets) == g$n_line_channels + 1)
  for (channel in seq_along(offsets)) {
    off = offsets[channel]
    abline(h = off, col = "lightgray")
    lines(scale*sct[, channel] + off, type = "l",
          col = channel,
          lwd = 2)
  }
  time_label = seq(0, nrow(ss)*time_step_stretched, by = g$time_ticks)
  ticks = time_label/time_step_stretched
  axis(1, ticks, labels = paste0(time_label), col = "black",
       padj = -1.2, pos = offset_step,
       tck = -0.01, col.axis = "black")
  dev.off()
  legend_file = legend_from_line_file_name(png_line_file)
  line_legend(legend_file, scale, max_p, g$image_height)
  invisible(NULL)
}

line_channels = function() {
  first_channel = as.integer(2*g$balloon_size) + 1
  c(1L, as.integer(seq.int(first_channel, g$image_height,
                           length.out = g$n_line_channels)))
}
