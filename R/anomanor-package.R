## usethis namespace: start
#' @import shiny
#' @import visNetwork
#' @import stringr
#' @import graphics
#' @import ggplot2
#' @import zeallot
#' @importFrom DBI dbGetQuery dbExecute dbAppendTable
#' @importFrom purrr map pluck set_names map2 map2_chr map_chr map_dfr map_lgl map_int
#' @importFrom magrittr %>%
#' @importFrom glue glue glue_sql
#' @importFrom dplyr case_when mutate select n left_join filter full_join summarize
#' @importFrom dplyr group_by rename if_else  bind_rows transmute group_modify
#' @importFrom dplyr arrange all_of pull right_join inner_join join_by across ungroup
#' @importFrom lubridate days format_ISO8601 hours now as_datetime
#' @importFrom dplyr collect tbl
#' @importFrom tidyr pivot_wider replace_na drop_na
#' @importFrom tidyselect ends_with
#' @importFrom tibble tibble tribble as_tibble rownames_to_column
#' @importFrom flextable flextable autofit bg
#' @importFrom shinyjs hide onclick removeClass runjs toggleElement toggleState
#' @importFrom shinyjs extendShinyjs onevent disable delay showElement js hideElement
#' @importFrom magick image_blank image_composite image_annotate image_write image_read
#' @importFrom magick image_info image_crop geometry_area geometry_point image_append
#' @importFrom magick image_join image_graph image_resize image_montage
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
# @importFrom withr defer
#' @useDynLib anomanor, .registration = TRUE
## usethis namespace: end
NULL

utils::globalVariables(c(
  "<<-",
  "annotation",
  "anon",
  "classification",
  "classification.x",
  "classification.y",
  "classification_phase",
  "color",
  "consensus_classification",
  "cnt",
  "email",
  "emailVerified",
  "history_date",
  "finalized",
  "firstName",
  "group",
  "id",
  "isdir",
  "label",
  "lastName",
  "marker",
  "method",
  "mtime",
  "mtime_dest",
  "mtime_store",
  "mtype",
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
  "user",
  "username",
  "verified",
  "width"
))

