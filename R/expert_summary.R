expert_summary = function(con){
  exp_sm = cleaned_expert_classification(con) |>
    select(record, method,  anon, phase, classification,
           consensus_classification, consensus_id, percent) |>
    dplyr::distinct()
  exp_sm
}