line_legend = function(legend_file, scale, max_p, image_height) {
#  max_p = 100
#  scale = 1.66/2
  stopifnot(is.list(g)) # requires globals
  offset_step = round(image_height/(g$n_line_channels + 1))
  if (file.exists(legend_file))
    return(legend_file)

  legend_w = g$line_legend_width
  scales = image_join(lapply(1:(g$n_line_channels + 1),
         function(i) mini_scale(offset_step, scale, legend_w, i)))
  # https://github.com/ropensci/magick/issues/330
  image_montage(scales,
                geometry = glue("{legend_w}x{offset_step}+0+0"),
                tile = glue("1x{g$n_line_channels + 1}"))  %>%
    image_resize(glue("{legend_w}!x{image_height}")) %>%
    image_write(legend_file, format = "png")
}

mini_scale = function(offset_step, scale, legend_w, channel){
  img = image_graph(width = legend_w, height = offset_step)
  par(mar = c(0,2.5,0,0), las = 1,
      bg = ifelse(channel == 1, "lightgray", colorspace::lighten(channel)))
  plot.new()
  ylim = c(0, offset_step/scale)
  plot.window(xlim = c(0,1), ylim = ylim, yaxs = "i")
  #seq(10, offset_step/scale, by = 10)
  axis(2, padj = 0.5, hadj = 0.8)
  dev.off()
  img
}

