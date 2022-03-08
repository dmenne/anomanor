user_datatable = function(stat) {
  ano_options = list(
    paging = FALSE,
    searching = FALSE,
    autoWidth = FALSE,
    dom = 'Bfrtip',
    buttons = c('copy', 'excel', 'pdf')
  )
  DT::datatable(
    stat,
    rownames = FALSE,
    extensions  = 'Buttons',
    filter = "none",
    options = ano_options
  ) %>%
  DT::formatStyle('verified',
    color = DT::styleEqual(c(FALSE, TRUE), c("red", ""))) %>%
  DT::formatStyle(
      'finalized',
      background = DT::styleColorBar(range(stat$finalized), 'lightblue'),
      backgroundSize = '98% 88%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'center'
    )
}
