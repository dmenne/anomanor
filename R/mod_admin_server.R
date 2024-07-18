mod_admin_server = function(id, app_user) {
  stopifnot(is.list(g))  # requires globals
  moduleServer(
    id,
    function(input, output, session) {
     rvalues = reactiveValues(
       request_user_table = 0,
       upload_file = NULL
     )
     ns = NS(id)
     iv = shinyvalidate::InputValidator$new()
     iv_email = shinyvalidate::InputValidator$new()
     iv_email$add_rule("new_user_email", shinyvalidate::sv_required())
     iv_email$add_rule("new_user_email", shinyvalidate::sv_email())
     iv_email$enable()

     disable("discard")
     disable("accept")

     # ----------- Admin Form -----------------------
     output$users_table = DT::renderDT({
       user_datatable(user_stats_table())
      })

     # -----------  User Statistics Table ------------
     user_stats_table = reactive({
       rvalues$request_usertable # toggled when new user added
       input$refresh_user
       stat = classification_user_statistics()
       req(stat)
       stat
     })


     observeEvent(input$new_user_email, {
       shinyjs::toggleState("invite_user", iv_email$is_valid())
     })

     # -------------- record summary table ----------------
     record_summary_table = reactive({
       input$refresh_record_summary
       classification_record_all()
     })

     output$record_summary_table = DT::renderDT({
       record_summary_table()
      },
      rownames = FALSE,
      options = list(paging = FALSE,searching = FALSE),
     )

     # -------------- Classification tables HRM ----------------
     classification_table_h = reactive({
       input$refresh_statistics_h
       ret = classification_statistics_html(method = 'h')
       req(ret)
       map(ret, function(x) {
         if (length(x) != 0)
           htmltools_value(x, ft.align = "left")
       })
     })

     output$classification_table_h = renderUI({
       classification_table_h()
     })

     # -------------- Classification tables Line plot ----------------
     classification_table_l = reactive({
       input$refresh_statistics_l
       ret = classification_statistics_html(method = 'l')
       req(ret)
       map(ret, function(x) {
         if (length(x) != 0)
           htmltools_value(x, ft.align = "left")
       })
     })

     output$classification_table_l = renderUI({
       classification_table_l()
     })

     # -------------- Invite user ----------------
     observeEvent(input$invite_user, {
       simul = if (!is.null(g$keycloak) &&
                   g$keycloak$active())
         ""
       else
         "<b>Simulated</b> "
       if (simul == "") {
         # nocov start
         # Check if user is already in database
         if (!is.null(g$keycloak$get_userid_from_email(input$new_user_email))) {
           shiny::showNotification(
             HTML(
               glue(
                 "User with email<br><code>{input$new_user_email}</code>",
                 "<br>is already registered"
               )
             ),
             id = "invite",
             closeButton = FALSE,
             type = "warning",
             session = session
           )
           req(FALSE)
         }
         added = g$keycloak$add_user(input$new_user_email, input$new_user_group)
         if (is.null(added)) {
           shiny::showNotification(
             glue("Invitation failed for {input$new_user_email}"),
             id = "invite",
             closeButton = FALSE,
             type = "error",
             session = session
           )
           req(FALSE)
         } else {
           # nocov end
           log_it(glue("Invited user {input$new_user_email} in group ",
                       "{input$new_user_group}"))
         }
       }
       shiny::showNotification(
         HTML(
           glue("{simul} Invitation sent to {input$new_user_email}")
         ),
         id = "invite",
         # gives shiny-notification-invite for css
         closeButton = FALSE,
         type = "message",
         session = session
       )
       updateTextInput(session, inputId = "new_user_email", value = "")
       rvalues$request_usertable = rvalues$request_usertable + 1
     })

     # --------------- Progress bar formatting ------------
     progress_bar = function(msg, background_color = "#007BFF") {
       js_upload = glue("$('#{ns('upload_progress')}').children()[0]")
       js_msg = glue("{js_upload}.innerHTML='{msg}'")
       runjs(js_msg)
     }

     # ----------------- Upload Message -------------------
     upload_file = reactive({
       file = input$upload
       req(file)
       ext = file_ext(file$datapath)
       if (!(all(ext %in% c("txt", "md")))) {
         msg = "Only .txt and .md files permitted"
         progress_bar(msg, '#DC3545')
         req()
       }
       # Upload success
       n = length(ext)
       s = ifelse(n == 1, "", "s")
       progress_bar(glue("Uploaded {n} file{s}"), '#DC3545')
       destination = ifelse(ext == "md",
                    file.path(g$patients_dir, file$name),
                    file.path(g$record_dir, file$name))
       if (file.exists(destination)) {
         updateActionButton(inputId = "accept", label = "Overwrite")
       } else {
         updateActionButton(inputId = "accept", label = "Accept")
       }
       #shinyjs::enable("accept")
       shinyjs::enable("discard")
       file
      })


     save_uploaded_file = function(file){
       # if file crashes on Windows when there are Umlauts, disable UTF-8
       # https://stackoverflow.com/questions/56419639/what-does-beta-use-unicode-utf-8-for-worldwide-language-support-actually-do
       is_md = file_ext(file$name) == "md"
       destination = ifelse(is_md,
              file.path(g$patients_dir, file$name),
              file.path(g$record_dir, file$name))
       overwritten = file.exists(destination)
       if (!is_md) {
         delete_record(file_path_sans_ext(file$name))
       } else {
         unlink(destination)
       }
       if (file.exists(destination))
         shiny::showNotification(HTML("Could not delete file to be overwritten"),
                          duration = 5,
                          session = session,
                          type = "error")
       file.copy(file$datapath, destination)
       if (overwritten) {
         log_it(glue("File {file$name} was uploaded and overwritten by {app_user}"))
       } else {
         cat()
         log_it(glue("File {file$name} was first-time uploaded by {app_user}"))
       }
       unlink(file$datapath)
       updateActionButton(inputId = "accept", label = "Accept")
       disable("accept")
       disable("discard")
       rvalues$upload_file = NULL
       if (!file.exists(destination))
         shiny::showNotification(HTML("Could not copy file to destination"),
                          duration = 5,
                          session = session,
                          type = "error")
       initial_record_cache()
       checked_patients = check_patient_records()
       update_record_choices()
       if (checked_patients != "")
         shiny::showNotification(HTML(checked_patients), type = "warning")
     }


     # ------------- Accept button ----------------------
     observeEvent(input$accept, {
       file = rvalues$upload_file
       save_uploaded_file(file)
     })

     # ------------- Discard button ----------------------
     observeEvent(input$discard, {
       file = rvalues$upload_file
       req(file)
       unlink(file$datapath)
       rvalues$upload_file = NULL
       updateActionButton(inputId = "accept", label = "Accept")
       disable("accept")
       disable("discard")
     })

     # ------------- Show result of upload --------------------
     output$check_data = renderUI({
       uf = upload_file()
       req(uf)
       rvalues$upload_file = uf
       if (file_ext(uf$name) == "md") {
         g$checked_patients = check_patient_records()
         shinyjs::enable("accept")
         HTML(includeMarkdown(uf$datapath))
       }
       else {
         cv = check_valid_record(uf$datapath, basename(uf$name))
         g$checked_patients = check_patient_records()
         # Change this if unexpected markers are to be suppressed
         can_accept = !(is.character(cv)) &&
           ((length(cv$missing) +
             length(cv$unexpected) +
             length(cv$duplicates)) == 0)
         toggleState("accept", can_accept)
         validation_table_html(cv)
       }

     })

     validation_table_html = function(cv){
       if (is.character(cv)) {
         disable("accept")
         disable("discard")
         tagList(
           h1("Error in anal manometry record"),
           h4(cv)
         )
       } else {
         # missing, unexpected, commented_markers
         expect_names = c("valid_markers", "missing", "unexpected",
                          "duplicates", "unused_markers", "invalid_channels")

         mks = c("Valid markers", "Missing markers", "Unexpected Markers",
                 "Duplicated Markers", "Unused Markers", "Invalid Channels")
         if (length(mks) != length(cv))
           log_it(glue("Invalid or missing marker name: {mks}, {names(cv)}"))
         map2(cv,  mks,  function(x, y) {
           if (length(x) == 0) return(NULL)
           d = data.frame(x)
           names(d) = y
           htmltools_value(
             flextable::flextable(d) %>%
               autofit() %>%
               bg(bg = "#E7F2FF", part = "header"),
             ft.align = "left"
           )
         })
       }
     }

     output$upload_ui = renderUI({
       input$discard # Do not use req() here
       input$accept
       fileInput(
         inputId = ns("upload"),
         label = h2("Upload manometry or patient file"),
         multiple = FALSE,
         buttonLabel = "Select file",
         placeholder = "Drag file here",
         accept = c(".txt", ".md")
       )
     })

     log_stat = reactive({
       input$refresh
       stat = dbGetQuery(g$pool,
          "SELECT time, message from ano_logs order by time desc limit 40")
     })

     output$log_table = DT::renderDT({
       DT::datatable(log_stat(),
         class = c("compact","stripe", "hover"),
         rownames = FALSE,
         filter = "top",
         options = list(paging = FALSE,
                        columnDefs = list(
                          list(width = 130, targets = 0)),
                        searching = TRUE))
     })

    output$download_database = downloadHandler(
      filename = function() {
        glue("anomanor_sqlite_{strftime(Sys.time(), '%Y-%m-%d_%H-%M')}.zip")
      },
      content = function(file){
        sql_file = file.path(dirname(file), "anomanor.sqlite")
        q = glue_sql("VACUUM into {sql_file}", .con = g$pool)
        dbExecute(g$pool, q)
        zip(file, sql_file, "-j")
        unlink(sql_file)
      },
      contentType = "application.zip"
    )

    # Manage page
    observeEvent(input$clear_cache, {
      unlink(paste0(g$png_dir, "/*"))
      unlink(paste0(g$cache_dir, "/*"))
      unlink(paste0(g$record_cache_dir, "/*"))
      unlink(paste0(g$html_dir, "/*"))
      log_it("Cache cleared")
      session$reload()
    })

    observeEvent(input$reset_me, {
      dbExecute(g$pool, glue_sql(
        "DELETE FROM classification where user = {app_user}", .con = g$pool))
      note = glue("Classifications for user {app_user} were erased")
      shiny::showNotification(note )
      log_it(note)
      session$reload()
    })

    observeEvent(input$generate, {
      generate_sample_classification(g$test_users, force = TRUE,
        expert_complete = TRUE, add_consensus = TRUE)
      log_it("Sample data generated")
      session$reload()
    })

    observeEvent(input$clear, {
      dbExecute(g$pool, "DELETE FROM classification")
      dbExecute(g$pool, "DELETE FROM ano_logs")
      log_it("Classfications deleted, log cleared")
      session$reload()
    })

    update_record_choices = function() {
      rec = dbGetQuery(g$pool, "SELECT record, anon_h, anon_l from record order by record")
      choice_names = glue("{rec$record} ({rec$anon_h}, {rec$anon_l})")
      choices = setNames(rec$record, choice_names)
      shinyWidgets::updatePickerInput(session, "select_delete_record",
                                      choices = choices, selected = NULL)
    }

    observe({
      shinyjs::toggleState("delete_record", input$select_delete_record != "")
    })

    observe( {
      input$management_panel
      update_record_choices()
    })

    observeEvent(input$delete_record, {
      delete_record(input$select_delete_record, delete_classifications = TRUE)
      update_record_choices()
    })

  })

}
