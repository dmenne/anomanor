update_consensus_classification = function(tbl) {
  tbl = tbl |>
    select(record, classification_phase, method, classification, n)
  majority = tbl |>
    group_by(record, classification_phase, method) |>
    summarize(max_n = max(n, na.rm = TRUE),
               sum_n = sum(n),
              .groups = "drop")

  recs = c("record", "classification_phase", "method")
  tbl1 = tbl |>
    left_join(majority, by = recs) |>
    mutate(percent = round(100*n/sum_n)) |>
    arrange(record, classification_phase, method)

  tbl_majority = tbl1 |>
    filter(n == max_n) |>
    group_by(record, classification_phase, method)  |>
    arrange(max_n) |>
    filter(dplyr::row_number() == 1) # Take the first if there are multiple

  # Get clinically supported ratings - this file is not included in the distribution
  # for privacy reasons
  clinical_file = rprojroot::find_package_root_file("data-raw", "clinical.xlsx")
  clinical = read_xlsx(clinical_file, "clinical") %>%
    select(-category) |>
    mutate(record = paste0(record, "_ib")) |>
    tidyr::pivot_longer(cols = 2:4, names_to = "classification_phase",
                        values_to = "clinical_classification") |>
    drop_na()

  tbl2 = tbl1 |>
    left_join(tbl_majority, by = recs)  |>
    mutate(percent = round(100 * n.x/sum_n.x))  |>
    select(record, classification_phase, method, classification = classification.x,
          n = n.x,
          percent = percent,
          majority_classification = classification.y) |>
    arrange(record, classification_phase, method)   |>
    left_join(clinical, by = c("record", "classification_phase"))   |>
    relocate(clinical_classification, .after = majority_classification)
  tbl2
}
