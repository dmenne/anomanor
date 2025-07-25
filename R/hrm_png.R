hrm_png = function(ss, png_hrm_file, max_p, time_step_stretched ) {
  stopifnot(is.list(g)) # Globals
  # Limit plot to range
  ss_lim = apply(ss, 1, function(x) {
    rev_limit(x, g$min_p, max_p)
  })
  png(png_hrm_file, width = ncol(ss_lim), height = nrow(ss_lim))
  par(mai = c(0, 0, 0, 0))
  graphics::image(seq_len(ncol(ss_lim)), seq_len(nrow(ss_lim)), t(ss_lim),
                  zlim = c(g$min_p, max_p),
                  useRaster = TRUE, col = g$color_lookup, axes = FALSE,
                  xlab = "", ylab = "")
  time_label = seq(0, ncol(ss_lim)*time_step_stretched, by = g$time_ticks)
  ticks = time_label/time_step_stretched
  axis(1, ticks, labels = paste0(time_label), col = "white",
       padj = -3.5, line = -.02, tck = 0.01, col.axis = "white")
  axis(3, ticks, col = "white", line = .2, tck = 0.02)
  dev.off()
  hrm_legend(max_p)
  invisible(NULL)
}
