render_md = function(markdown_file){
  stopifnot(is.list(g)) # globals
  markdown_md = glue("{g$md_dir}/{markdown_file}.md")
  stopifnot(file.exists(markdown_md))
  md_time = file.info(markdown_md)$mtime
  markdown_html = normalizePath(
    glue("{g$html_dir}/{markdown_file}.html"), mustWork = FALSE)
  if (!file.exists(markdown_html) ||
      (md_time > file.info(markdown_html)$mtime) ) {
    if (!rmarkdown::pandoc_available())  {
      if (getenv_r_config_active() != "test")
        shinyWidgets::show_alert(title = "Pandoc missing",
                 text = "Cannot show this help text because Pandoc is not installed",
                 type = "warning")
      return(NULL)
    }
    output_format = rmarkdown::html_document(
      theme = NULL, highlight = NULL, mathjax = NULL)
    # This fails when the directory read from is readonly
    # So copy it to temporary directory
    # All png-files must be of form  {markdown_file}_xxx.png
    # https://github.com/rstudio/rmarkdown/issues/1839
    pattern = glue("{file_path_sans_ext(markdown_file)}")
    cp_files = dir(g$md_dir, pattern = pattern, full.names = TRUE)
    file.copy(from = cp_files, to = tempdir(), overwrite = TRUE)
    markdown_tmp = glue("{tempdir()}/{markdown_file}.md")
    unlink(markdown_html)
    rmarkdown::render(markdown_tmp,
                      runtime = "shiny",
                      output_format = output_format,
                      output_file = markdown_html,
                      quiet = TRUE)
    stopifnot(file.exists(markdown_html))
    copied_files = dir(tempdir(), pattern, full.names = TRUE)
    file.remove(copied_files)
    log_it(glue("Rendered {markdown_file}"))
  }
  markdown_html
}
