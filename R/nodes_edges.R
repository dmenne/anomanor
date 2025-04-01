
nodes_edges = function(con) {
  # To force a regenerate, DROP TABLE nodes; DROP TABLE edges
  nodes_exists = check_if_table_exists(con, "nodes")
  edges_exists = check_if_table_exists(con, "edges")
  both_exist = nodes_exists && edges_exists
  if (both_exist) {
    nodes = dbReadTable(con, "nodes")
    edges = dbReadTable(con, "edges")
    return(list(nodes = as_tibble(nodes), edges = as_tibble(edges)))
  }
  if (nodes_exists) dbExecute(con, "DROP TABLE nodes")
  if (edges_exists) dbExecute(con, "DROP TABLE edges")
  nodes_file = rprojroot::find_package_root_file("data-raw", "nodes_edges.xlsx")
  nodes = readxl::read_xlsx(nodes_file, "nodes") |>
    mutate(
      title = str_replace_all(str_wrap(title, 40), "\\n", "<br>"),
      x = x*280,
      y = y*130
    ) |>
    select(label, short, id, phase, group, x, y) |>
    mutate(caption = str_replace(short, "poor propulsion","pp")) |>
    mutate(caption = str_replace_all(caption, "expulsion","ex")) |>
    mutate(caption = str_replace_all(caption, "oo","")) |>
    mutate(caption = str_replace_all(caption, " ","")) |>
    mutate(caption = str_replace_all(caption, ";","")) |>
    mutate(caption = paste(substring(phase, 1, 1),
                           substring(caption, 1,16), sep = "_")) |>
    mutate(column = paste(phase, id, sep = " "))  |>
    mutate(column = as.integer(as.factor(column))) |>
    arrange(column) |>
    select(label, id, phase, group, short, caption, x, y)

  edges = readxl::read_xlsx(nodes_file, "edges") |>
    mutate(id = 1:n(), .before = "phase" )

  # Save to database
  dbWriteTable(con, "nodes", nodes )
  dbWriteTable(con, "edges", edges )

  list(nodes = as_tibble(nodes), edges = as_tibble(edges))

  #  usethis::use_data(nodes, edges, overwrite = TRUE, internal = TRUE)
}
