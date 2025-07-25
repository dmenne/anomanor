nodes_edges = function(con) {
  # To force a regenerate, DROP TABLE nodes; DROP TABLE edges
  nodes_exists = check_if_table_exists(con, "nodes")
  edges_exists = check_if_table_exists(con, "edges")
  both_exist = nodes_exists && edges_exists
  if (both_exist) {
    nodes = DBI::dbReadTable(con, "nodes")
    edges = DBI::dbReadTable(con, "edges")
    return(list(nodes = nodes, edges = edges))
  }
  if (nodes_exists) dbExecute(con, "DROP TABLE nodes")
  if (edges_exists) dbExecute(con, "DROP TABLE edges")
  nodes_file = rprojroot::find_package_root_file("data-raw", "nodes_edges.xlsx")
  print(nodes_file)
  stopifnot(file.exists(nodes_file))
  nodes = read_xlsx(nodes_file, "nodes") %>%
    mutate(
      title = str_replace_all(str_wrap(title, 40), "\\n", "<br>"),
      x = x*280,
      y = y*130
    )
  DBI::dbWriteTable(con, "nodes", nodes )

  edges = read_xlsx(nodes_file, "edges") %>%
    mutate(id = seq_len(n()), .before = "phase" )
  DBI::dbWriteTable(con, "edges", edges )
  list(nodes = nodes, edges = edges)

  #  usethis::use_data(nodes, edges, overwrite = TRUE, internal = TRUE)
}
