mod_admin_ui = function(id, ...) {
  ns = NS(id)
  col_width = 800
  tagList(
    tabsetPanel(
      tabPanel(
        "Users",
        wellPanel(
          id = ns("new_user_panel"),
          splitLayout(
            cellWidths = c(280, 160, 130),
            textInput(ns("new_user_email"), "New user email ",
                      placeholder = "Enter email address"),
            selectInput(
              ns("new_user_group"),
              "User group",
              selectize = FALSE,
              choices = c("trainees", "experts") # "admins")
            ),
            shinyWidgets::actionBttn(ns("invite_user"), label = "Invite"),
          ),
          # splitLayout
          helpText(HTML(
            glue(
              "On this page, only invitations of new users are possible. ",
              "All other actions, such as a promotion to admin or a removal of a ",
              "user must be done from the {g$keycloak_site}."
            )
          ))
        ),
        # wellPanel
        DT::DTOutput(ns("users_table"))
      ),
      # tabPanel record summary
      tabPanel(
        id = ns("record_summary_panel"),
        "Records",
        shinyWidgets::actionBttn(ns("refresh_record_summary"), "Refresh"),
        helpText(HTML("For records without classification, the anonymized names (anon) are not displayed. If you must find the association, e.g. to correct a record, use the dropdown near the <b>Delete</b> button on the Manage-tab.")),
        DT::DTOutput(ns("record_summary_table"), width = "300px")
      ),
      # tabPanel User
      tabPanel(
        id = ns("classification_panel_h"),
        "HRM Classification",
        shinyWidgets::actionBttn(ns("refresh_statistics_h"), "Refresh"),
        uiOutput(ns("classification_table_h")),
        helpText(g$krip_text)
      ),
      tabPanel(
        id = ns("classification_panel_l"),
        "Line Classification",
        shinyWidgets::actionBttn(ns("refresh_statistics_l"), "Refresh"),
        uiOutput(ns("classification_table_l")),
        helpText(g$krip_text)
      ),
      # tabPanel upload
      tabPanel(
        id = ns("upload_panel"),
        "Upload",
        #https://stackoverflow.com/a/54423662/229794
        uiOutput(ns('upload_ui')),
        helpText(
          "To see uploaded records in the record dropdown, refresh the browser(F5)",
          id = "upload_help"),
        shinyWidgets::actionBttn(ns("accept"), "Accept"),
        shinyWidgets::actionBttn(ns("discard"), "Discard", color = "warning"),
        uiOutput(ns("check_data"))
      ),
      # tabPanel upload
      tabPanel(
        id = ns("database_panel"),
        "Database",
        h1("40 most recent log entries"),
        shinyWidgets::actionBttn(ns("refresh"), "Refresh"),
        DT::DTOutput(ns("log_table"))
      ),
      tabPanel(
        id = ns("management_panel"),
        "Manage",
        fillPage(
          h2("Maintenance"),
          fillRow(
            flex = c(1,3),
            downloadButton(ns("download_database"), "Download Database"),
            helpText("Download the zipped SQLite database file. Use this before you perform any risky operations on this page. Restoring data from an existing SQLite backup must be done by the system admin currently."),
            width = col_width,  height = 70
          ),
          fillRow(
            flex = c(1,3),
            shinyWidgets::actionBttn(ns("clear_cache"), "Clear cache"),
            helpText("HRM and conventional displays are created on the fly when requested for the first time, and stored in a cache for future faster retrieval. Use this button when old style images turn up and you want to force a refresh of the cache. No classification data will be deleted."),
            width = col_width,  height = 70
          ),
          fillRow(
            flex = c(1,3),
            shinyWidgets::actionBttn(ns("reset_me"), "Reset me"),
            helpText(HTML("This will erase all classifications for the currently logged-in admin user. No relevant information is destroyed, because classifications entered by the admin users are only stored, but discarded in statistics. Use this when you want to reset you classification for a demonstration, so your and only your ratings are back to the <b>?</b>-state.")),
            width = col_width,  height = 70
          ),
          h2("Danger zone"),
          wellPanel(
            width = col_width + 20,
            fillRow(
              flex = c(1, 3),
              fillCol(
                shinyWidgets::pickerInput(inputId = ns("select_delete_record"),
                                          width = 190,
                                          choices = NULL,
                                          selected = NULL,
                                          options = list(`live-search` = TRUE,
                                             title = "Select record")),
                shinyWidgets::actionBttn(ns("delete_record"), "Delete",
                                       color = "danger")
              ),
            helpText(HTML("Select record for deletion. This will also delete associated classifications, so be sure to request a database backup before deleting files. In the dropdown box, the anonymized record names are shown in brackets.<br>You can use the dropdown without deleting the record to determine the association between file name and anonymized name.<br><b>Do not delete a record</b> when you have made changes and want to keep old classifications. Instead, upload the changed file, and confirm when asked to overwrite the existing version.")),
              width = col_width, height = 150
            ),
            hr(),
            fillRow(
              flex = c(1,3),
              shinyWidgets::actionBttn(ns("clear"), "Clear", color = "danger"),
              helpText(HTML("<b>Danger</b>: This will delete all classifications, without creating randomized new data. Use it when you want to start a test run from scratch. The log file will also be cleared.")),
              width = col_width, height = 60
            ),
            fillRow(
              flex = c(1,3),
              shinyWidgets::actionBttn(ns("generate"), "Test data",
                                       color = "danger"),
              helpText(HTML("<b>Danger:</b> This will delete all classifications and create a new set of simulated random data. Use it only in test mode!")),
              width = col_width, height = 60
            ),
          )
        ),
      ) # tabPanel
    ) #tabsetPanel
  )# tagList
}

