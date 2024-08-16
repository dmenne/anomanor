get_random_record = function(chs, selected) {
  if (is.null(selected) || selected == "") return(selected)
  chsc = chs$choices
  all_ch = rapply(chsc, c)
  sel =  which(stringr::str_detect(
    all_ch, stringr::fixed(selected)))
  if (length(sel) != 0) {
    selected_is_ex =
      stringr::str_detect(names(all_ch)[sel],stringr::fixed("$ex"))
    if (selected_is_ex) return(selected)
  }
  # Do not return $ex if not necessary
  remove_ex = function(x){
    x[!str_detect(names(x), fixed("$ex"))]
  }
  chsc = purrr::map(chsc, remove_ex)
  chsc_p = chsc$Partial[chsc$Partial != selected]
  if (length(chsc_p) != 0)
    return(as.character(sample(chsc_p,1)))
  chsc_t = chsc$ToDo[chsc$ToDo != selected]
  if (length(chsc_t) != 0 )
    return(as.character(sample(chsc_t,1)))
  return(selected)
}

