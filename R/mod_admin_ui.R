mod_admin_ui = function(id, ...) {
  ns = NS(id)
  col_width = 800
  tagList(
    tabsetPanel(
      #id = "tabset_admin",
      # user
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
          )),
          helpText(HTML("To see the user table, at least one classification
                        must be present"
          ))
          ),
        # wellPanels
        shinyWidgets::actionBttn(ns("refresh_users"), "Refresh"),
        DT::DTOutput(ns("user_table"))
      ),
      # tabPanel record summary
      tabPanel(
        id = ns("record_summary_panel"),
        "Records",
        shinyWidgets::actionBttn(ns("refresh_record_summary"), "Refresh"),
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
        DT::DTOutput(ns("log_table"), width = 700)
      ),
      tabPanel(
        id = ns("management_panel"),
        "Manage",
        fillPage(
          h2("Maintenance"),
          fillRow(
            flex = c(1,3),
            downloadButton(ns("download_database"), "Download Database"),
            helpText("Download the zipped SQLite database file. Use this before performing any risky operations on this page. Restoring data from an existing SQLite backup must currently be done by the system administrator."),
            width = col_width,  height = 70
          ),
          fillRow(
            flex = c(1,3),
            shinyWidgets::actionBttn(ns("clear_cache"), "Clear cache"),
            helpText("HRM and conventional displays are created on the fly the first time they are requested and stored in a cache for faster future retrieval. Use this button when old style images appear and you want to force a cache refresh. Classification data is not deleted."),
            width = col_width,  height = 70
          ),
          fillRow(
            flex = c(1,3),
            shinyWidgets::actionBttn(ns("reset_me"), "Reset me"),
            helpText(HTML("This will delete all classifications for the currently logged in Admin user. No relevant information will be destroyed, because classifications entered by admin users are only stored, but discarded in the statistics. Use this if you want to reset your classification for a demonstration, so that your and only your ratings are back to <b>?</b>-status.")),
            width = col_width,  height = 70
          ),
          h2("Danger zone", id = "danger-zone"),
          # *** Remove this to show danger elements
#          shinyjs::hidden(
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
              helpText(HTML("<b>Danger</b>: This will delete all classifications, without creating randomized new data. Use his if you want to start a test run from scratch. The log file will also be cleared.")),
              width = col_width, height = 60
            ),
            fillRow(
              flex = c(1,3),
              shinyWidgets::actionBttn(ns("generate"), "Test data",
                                       color = "danger"),
              helpText(HTML("<b>Danger:</b> This will delete all classifications and create a new set of simulated random data. Use this in test mode only!")),
              width = col_width, height = 60
            ),
          )
        ),
      ), # management tabPanel
      tabPanel(
        id = ns("history_panel"),
        "History",
        fillPage(
          plotOutput(ns("history_plot")),
          helpText("History is refreshed every hour on restart; latest changes may not yet show. Administrator ratings are not shown.")
        )
      )  # history tabPanel
    ) #tabsetPanel
  )# tagList
}
