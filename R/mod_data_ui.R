mod_data_ui = function(id, ...) {
  ns = NS(id)
  tippies = c(
    back = "Back<br><small>Left Cursor Key</small>",
    forward = "Forward<br><small>Right Cursor Key</small>",
    london_classification = "London 1 classification<br>for this phase"
  )
  tp = function(tippy) tippy::tippyThis(ns(tippy), tippies[[tippy]])
  tagList(
    tippy(
      shinyWidgets::switchInput(
        inputId = ns("classification_method"),
        label = "Method",
#        value = TRUE, ### DEBUG
        size = "small",
        onLabel = "Conventional",
        offLabel = "HRM"
      ),
      HTML("Switch between HRM and conventional view.<br><b>A different random record will be displayed after switching.</b><br>For example cases, the same record will be displayed.")
    ),
    shinyWidgets::progressBar(ns("completed"), value = 0, display_pct = TRUE),
    # Error message when using tippy directly on progressBar, ok with tippyThis
    tippyThis(ns("completed"), "Percent of task completed: 50% HRM, 50% conventional"),
    tags$style(glue("#{ns('help')} {{margin-top:26px}}")),
    fillRow(
      tippy(
        shinyWidgets::pickerInput(ns("record"), "Record", width = "100px",
                      choices = NULL, options = list(`icon-base` = "fa")),
        "Anonymized short record name. Patient records have different names for HRM and for the conventional method to avoid bias. Please report any problems by citing this name."
      ),
      shinyWidgets::actionBttn(
        ns("help"),  "Help", style = "bordered", size = "sm",
        color = "primary", icon = icon("question-circle")),
      height = "75px",
      flex = c(2,1)
    ),
    tippy(
      shinyWidgets::pickerInput(ns("classification_phase"), "Classification Phase",
                                choices = "all", options = list(`icon-base` = "fa")),
      "Select 'All' to view the patient report and the full marker set. For classification, select one of the numbered items in sequence.<br>When 'Classification Phase' is not 'All', only relevant protocol sections are unveiled.</br>",
      placement = 'right'
    ),
    shinyWidgets::actionBttn(ns("back"), NULL,  size = "lg", icon = icon("caret-left")),
    shinyWidgets::actionBttn(ns("forward"), NULL, size = "lg", icon = icon("caret-right")),
    shinyWidgets::actionBttn(ns("london_classification"),
                             label = img(src = "www/london1.png") ),
    lapply(names(tippies), tp),
    htmlOutput(ns("todo"), inline = TRUE),
    tippy(
      selectizeInput(ns("protocol_phase_start"),
      "Protocol Phase", choices = NULL),
      "Phase markers relevant<br>for this classification phase",
      placement = 'right'
    )
  )
}

