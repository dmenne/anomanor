Sys.setenv("R_CONFIG_ACTIVE" = "test")

globals()
withr::defer(cleanup_test_data())

test_that("Can render all md files", {
  expect_true(rmarkdown::pandoc_available())
  unlink(g$html_dir, recursive = TRUE)
  dir.create(g$html_dir)
  mds = file_path_sans_ext(dir(g$md_dir, "^.*\\.md$"))
  g$config$log_console = TRUE
  purrr::walk(mds, ~checkmate::expect_file_exists(render_md(.)))
  # No output on second run
  purrr::walk(mds, function(x) {
    expect_output(render_md(x), NA)
  })
})
