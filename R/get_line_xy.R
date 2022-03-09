get_line_xy = function(dt, start_time, x1, y1, x2, y2, view, time_step, time_zoom)
{
  # https://stackoverflow.com/a/20001797/229794
  stopifnot(ncol(dt) == g$image_height) # To check only, image_height is global
  must_swap = (view == 1 && x1 > x2) || (view == 2 && y1 > y2 )
  if (must_swap) {
    xx1 = x1
    yy1 = y1
    x1 = x2
    y1 = y2
    x2 = xx1
    y2 = yy1
  }
  # Take into account offset
  x1 = x1 + start_time
  x2 = x2 + start_time
  steps = max( abs(x1 - x2), abs(y1 - y2), 2)
  id =  cbind(round(seq(x1, x2, length.out = steps) ,0),
              round(seq(y1 + 1, y2 + 1, length.out = steps) ,0))
  id  = id[id[,1] >= 0 & id[,2] >= 0 & id[,1] < nrow(dt) & id[,2] < ncol(dt),]
  if (nrow(id) == 0) return(NULL) # All off-screen
  where = ifelse(id[,2] <= g$balloon_size, "balloon",
          ifelse(id[,2] <= 2*g$balloon_size, "gap",
          "sensor"))
  press = apply(id, 1, function(idx) dt[idx[1], idx[2]])/10
  ret = data.frame(
    time = round(id[,1]*time_step,1),
    pos = round(y_to_pos(id[,2]),2),
    press = round(press,1),
    where = where) %>%
  dplyr::arrange(.data$time, .data$pos)
  ret = ret[ret$where != "gap",]
  attr(ret, "balloon_press") = dt[id[1],1]/10
  ret
}


