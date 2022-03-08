ano_bttn = function(inputId, icon = inputId, color = "success") {
  # https://community.rstudio.com/t/use-of-open-source-icons-in-shiny/110056/5
  # Could not get the above to work with actionButton
  shinyWidgets::actionBttn(inputId = inputId, label = str_to_title(inputId), 
             size = "sm", block = TRUE , 
             icon = icon(icon),
             style = "material-flat",
             color = color
             )
}

