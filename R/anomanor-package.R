## usethis namespace: start
#' @import shiny
#' @import visNetwork
#' @import stringr
#' @import graphics
#' @import ggplot2
#' @importFrom DBI dbGetQuery dbExecute dbAppendTable
#' @importFrom purrr map pluck set_names map2 map2_chr map_chr map_dfr map_lgl map_int
#' @importFrom magrittr %>%
#' @importFrom glue glue glue_sql
#' @importFrom dplyr case_when mutate select n left_join filter full_join summarize
#' @importFrom dplyr group_by rename if_else  bind_rows transmute group_modify
#' @importFrom dplyr arrange all_of pull right_join inner_join join_by across
#' @importFrom dplyr rows_update distinct pull relocate
#' @importFrom lubridate days format_ISO8601 hours now as_datetime
#' @importFrom tidyr pivot_wider replace_na drop_na pivot_longer
#' @importFrom tidyselect ends_with
#' @importFrom tibble tibble tribble as_tibble rownames_to_column
#' @importFrom flextable flextable autofit bg
#' @importFrom shinyjs hide onclick removeClass runjs toggleElement toggleState
#' @importFrom shinyjs extendShinyjs onevent disable delay showElement js hideElement
#' @importFrom magick image_blank image_composite image_annotate image_write image_read
#' @importFrom magick image_info image_crop geometry_area geometry_point image_append
#' @importFrom magick image_join image_graph image_resize image_montage
#' @importFrom readr read_file
#' @importFrom tippy tippy tippy_global_theme tippyThis
#' @importFrom tools file_path_sans_ext file_path_as_absolute file_ext
#' @importFrom stats setNames na.omit time
#' @importFrom rlang .data
#' @importFrom grDevices colorRampPalette dev.off png
#' @importFrom graphics abline arrows axis lines par plot.new plot.window polygon
#' @importFrom graphics rect text title
#' @importFrom stats median na.omit predict quantile rbinom rnorm setNames
#' @importFrom utils file_test read.delim zip
#' @importFrom httr GET PUT POST DELETE status_code
#' @importFrom shiny shinyApp showNotification
#' @importFrom flextable flextable set_header_labels add_header_row
#' @importFrom flextable set_caption add_footer merge_at bg set_table_properties
#' @importFrom flextable htmltools_value
#' @importFrom flextable htmltools_value
#' @importFrom stringi stri_rand_strings
#' @importFrom scales col_numeric
#' @importFrom conflicted conflicts_prefer
#' @importFrom readxl read_xlsx
#' @importFrom zeallot "%<-%"
#' @importFrom withr defer
#' @useDynLib anomanor, .registration = TRUE
## usethis namespace: end
NULL

utils::globalVariables(c(
  "<<-",
  "annotation",
  "anon",
  "category",
  "classification",
  "classification.x",
  "classification.y",
  "classification_phase",
  "clinical_classification",
  "cnt",
  "color",
  "consensus_classification",
  "email",
  "emailVerified",
  "finalized",
  "firstName",
  "group",
  "history_date",
  "id",
  "impute",
  "isdir",
  "label",
  "lastName",
  "majority_classification",
  "marker",
  "max_n",
  "method",
  "mtime",
  "mtime_dest",
  "mtime_store",
  "mtype",
  "n.x",
  "n_total",
  "patient.x",
  "patient.y",
  "percent",
  "phase",
  "pos",
  "record",
  "rowname",
  "rowname.x",
  "sec",
  "short",
  "sum_n",
  "sum_n.x",
  "user",
  "username",
  "verified",
  "width",
  "x",
  "y"
))

