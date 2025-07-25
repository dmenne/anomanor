delete_record = function(record, delete_classifications = FALSE) {
  deleted_record_dir = file.path(g$record_dir, "deleted")
  deleted_patients_dir = file.path(g$patients_dir, "deleted")
  safe_create_dir(deleted_record_dir)
  safe_create_dir(deleted_patients_dir)
  save_file_rename(file.path(g$record_dir, glue("{record}.txt")),
              file.path(deleted_record_dir, glue("{record}.txt")))
  save_file_rename(file.path(g$patients_dir, glue("{record}.md")),
              file.path(deleted_patients_dir, glue("{record}.md")))
  unlink(file.path(g$record_cache_dir, glue("{record}*.rds")))
  images = dbGetQuery(g$pool, glue_sql(
    "SELECT anon_l, anon_h from record where record = {record}", .con = g$pool))
  unlink(file.path(g$png_dir, glue("{images$anon_l}_*.png")))
  unlink(file.path(g$png_dir, glue("{images$anon_h}_*.png")))
  unlink(file.path(g$png_dir, glue("scale_{images$anon_l}_*.png")))
  unlink(file.path(g$png_dir, glue("scale_{images$anon_h}_*.png")))
  # Classification will be deleted automatically
  if (delete_classifications)
    dbExecute(g$pool, glue_sql("DELETE FROM record WHERE record={record}",
                             .con = g$pool))
}
