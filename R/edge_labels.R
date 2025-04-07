edge_labels = function(ec, edges) {
  max_percent =  suppressWarnings(max(ec$percent, na.rm = TRUE))
  if (max_percent == -Inf) max_percent = 100
  ec1 = ec  |>
    mutate(
      label = glue("{label}\n{percent}%" ),
      color = case_when(
        ( percent == max_percent ) |
        ( majority_classification == classification) ~ "green",
        ( !is.na(clinical_classification)) &
        ( majority_classification != clinical_classification ) &
        ( classification == clinical_classification ) ~ "red",
        TRUE ~ "darkgray"),
      width = if_else(
        majority_classification == classification, 9,
        percent/12 + 1)
    )  |>
    select(id, label, color, width)#
}

