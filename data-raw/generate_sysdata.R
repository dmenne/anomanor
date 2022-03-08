## code to prepare dataset goes here
## Run it whenever nodes_edges.xlsx changes

nodes_file = rprojroot::find_package_root_file("data-raw", "nodes_edges.xlsx")

nodes = readxl::read_xlsx(nodes_file, "nodes") %>%
  mutate(
    title = str_replace_all(str_wrap(title, 40), "\\n", "<br>"),
    x = x*280,
    y = y*130
  )
edges = readxl::read_xlsx(nodes_file, "edges") %>%
  mutate(id = 1:n(), .before = "phase" )
usethis::use_data(nodes, edges, overwrite = TRUE, internal = TRUE)
