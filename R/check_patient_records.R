check_patient_records = function(){
  stopifnot(is.list(g)) # globals
  p_files = file_path_sans_ext(dir(g$patients_dir, "^.*\\.md$"))
  r_files = file_path_sans_ext(dir(g$record_dir, "^.*\\.txt$"))
  mt = tibble(patient = p_files) %>%
    full_join(tibble(patient = r_files), by = "patient", keep = TRUE)

  no_record = paste0(
    mt %>%
    filter(is.na(patient.x)) %>%
    select(patient.y) %>%
    unlist(),
    collapse = "</li><li>\n" )
  no_patient = paste0(
    mt %>%
    filter(is.na(patient.y)) %>%
    select(patient.x) %>%
    unlist(),
   collapse = ", " )
  msg = ""
  if (no_record != "")
    msg = paste0("<b>Records without patient report:</b><ul><li>",
                 no_record, "</li></ul>" )
  if (no_patient != "")
    msg = paste0(msg, "<b>Patient reports without record:</b><ul><li>",
                 no_patient, "</li></ul>" )
  msg
}
