app_ui = function(request) {
  addResourcePath('www', app_sys('app/www'))
  tagList(
    shinyjs::useShinyjs(),
    fluidPage(
      title = glue("Anal manometry {packageVersion('anomanor')}"),
      keys::useKeys(),
      keys::keysInput("keys", g$hotkeys),
      tags$style(HTML(paste0(
        "body{overflow-y: auto;}",
        "#canvas1{margin-left:", g$hrm_legend_width, "px}",
        "#canvas2{margin-left:", g$line_legend_width, "px}")),
      ),
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "www/custom.css"),
        HTML('
          <link rel="apple-touch-icon" sizes="180x180" href="www/apple-touch-icon.png">
          <link rel="icon" type="image/ico" sizes="32x32" href=""www/favicon.ico">
          <link rel="icon" type="image/png" sizes="32x32" href=""www/favicon-32x32.png">
          <link rel="icon" type="image/png" sizes="16x16" href=""www/favicon-16x16.png">')
      ),
      extendShinyjs("www/lines.js",
        functions = c("image_clicked", "mouse_move", "canvas_resize", "clear_all",
                      "enable_add", "set_marker_mode", "draw_section",
                      "mouse_move2")),
      sidebarLayout(
        sidebarPanel(
          id = "sidebar_panel",
          titlePanel("Anorectal Manometry"),
          wellPanel(
            id = "in_sidebar_well",
            mod_data_ui("dm"),
            textOutput("readout_hrm_value"),
            tableOutput("readout_conventional_value"),
            imageOutput("section", height = "270px"),
            div(
              id = "section_value_div",
              uiOutput("section_value", class = "shiny-html-output")
            ),
            fluidRow(
              splitLayout(
                cellWidths = c("35%", "55%"),
                shinyWidgets::sliderTextInput(
                    inputId = "time_zoom",
                    label = "Zoom (+/- key)",
                    force_edges = TRUE,
                    grid = TRUE,  width = "100px",
                    choices = g$time_zoom_levels),
                shinyWidgets::sliderTextInput(
                  "max_p", "Scale", grid = TRUE,
                  force_edges = TRUE,
                  choices = g$pressure_choices)
                )
            ),
        ),
         helpText("Press F11 or Control \u2318-F (Mac) for full-screen view"),
         conditionalPanel("output.is_admin", tippy(
            shinyWidgets::switchInput(
              inputId = "admin",
              "Administrator",
              value = FALSE,
              size = "small"),
              "View results. Only available when logged in as administrator"),
          ),
          tags$a(href = "/logout", "Logout"),
          shinyWidgets::actionBttn("help_about", NULL, icon = icon("info")),
          textOutput("user"),
          bookmarkButton(),
          width = 3
        ), # sidebarPanel
        mainPanel(
          id = "main_panel",
          conditionalPanel("input.admin == false",
           div(id = "image-container",
               imageOutput("mainimage"),
               uiOutput("canvas")
           ),
           fluidRow(
             id = "patient_panel",
             column(12, uiOutput("patient_text")),
             column(12, uiOutput("legend_text")),
             column(10, mod_visnet_ui("ano", height = 300)),
             column(2,
               id = "save_panel",
               ano_bttn("save"),
               ano_bttn("cancel", "xing", "warning"),
               ano_bttn("finalize", "flag-checkered"),
               textAreaInput(
                 "comment", label = "", height = "200px",
                  placeholder = "Optional comment")
              )
           ) # fluidRow
          ), # conditionalPanel no-admin,
          width = 9
        ) # mainPanel
      ), # sidebarLayout
      tippy_all() # See tippy_text.R,
    ) # fluidPage
  )
}
