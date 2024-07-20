# ------------------- filter_markers  -------------------------------------
filter_markers = function(markers, classification_ph) {

  if (nrow(markers) == 0 || classification_ph == 'all')
    return(markers)
  fmcp = g$mcp %>%
    filter(g$mcp$classification_phase == classification_ph)
  markers %>%
    right_join(fmcp,  by = c("annotation" = "marker")) %>%
    select(-classification_phase, -mtype) %>%
    drop_na(sec)
}
