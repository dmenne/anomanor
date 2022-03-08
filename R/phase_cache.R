phase_cache = function(file, method, max_p, active_begin, phase_label,
                            active_width, window_width, time_zoom) {
  #dput(mget(ls()))
  # Generate full range cache and image - will be skipped if file exists
  cache_file = record_cache(file, max_p, time_zoom)$cache_file
  if (is.null(cache_file)) return(NULL)
  stopifnot(file.exists(cache_file))
  active_begin = max(as.integer(active_begin)*time_zoom, 0L)
  # Force minimal window width
  active_width = max(as.integer(active_width*time_zoom), 30L)
  png_phase_file = png_phase_file_name(file, method, max_p, active_begin,
                   active_width, window_width, phase_label, time_zoom)
  # Return file name if already in cache
  if (file.exists(png_phase_file)) {
    return(png_phase_file)
  }
  # Create cache file
  png_file = png_file_name(file, method, max_p, time_zoom)
  image = image_read(png_file)
  window_height = image_info(image)$height
  # Protect against unexpected changes
  stopifnot(window_height == g$image_height)
  image_width = image_info(image)$width

  start_time = record_start_time(active_begin, active_width, window_width, image_width)
  screen_left_width = max((active_begin - start_time), 0)
  screen_right_width =
    (window_width - screen_left_width - active_width)

  screen_left = image_blank(screen_left_width, window_height, color = "lightgray")
  screen_right = image_blank(screen_right_width, window_height, color = "lightgray")
  screen_dummy = image_blank(window_width, g$balloon_size + 1, color = "lightgray")
  phase_label = str_wrap(phase_label, active_width/6)
  operator = ifelse(method == "h", "HardLight", "Screen")
  operator_dummy = ifelse(method == "h", "atop", "Darken")
  annot = tribble(
    ~label, ~pos,
    "balloon", 0.02,
    "proximal", 0.17,
    "distal", 0.94,
    phase_label, 0.08
  )
  img = image %>%
    image_crop(geometry_area(window_width, window_height, start_time, 0)) %>%
    image_composite(screen_dummy, geometry_point(0, g$balloon_size - 2),
                    operator = operator_dummy ) %>%
    image_composite(screen_left, operator = operator )  %>%
    image_composite(screen_right,
        offset = geometry_area(x_off = window_width - screen_right_width),
        operator = operator )
  for (i in 1:nrow(annot)) {
    a = annot[i,]
    color = if (method == 'h' & i != 4)  "white" else "black"
    boxcolor = if (i <= 3) NULL else
               if (color == "white") "black" else "white"
    img = img %>%
      image_annotate(glue(" {a$label} "),
       location = geometry_point(
         screen_left_width + 5,
         a$pos*g$image_height),
         color = color,
         font = "Trebuchet",
         weight = 700,
         boxcolor = boxcolor,
         size = 14)
  }
  legend_file = ifelse(method == 'h', legend_file_name(max_p),
                       legend_from_line_file_name(png_file))
  scale_img = image_read(legend_file)
  img = image_append(c(scale_img, img))
  # Create png
  image_write(img, path = png_phase_file, format = "png")
  #log_it(glue("image_write {basename(png_phase_file)}"))
  png_phase_file
}

