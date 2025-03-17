app_server = function(input, output, session) {

  # ----------- Database ---------
  if (!file.exists(g$sqlite_path)) stop("No database available")
  #  new_marker_x = NULL
  max_p_hrm = 100 # Session settings
  max_p_line = 100
  ns_ano = NS("ano") # Access to visual tree network
  ns_dm = NS("dm") # Access to data module
  app_user = get_app_user(session)
  app_groups = get_app_groups(app_user)
  is_admin = str_detect(app_groups, "admins")
  n_classified = number_of_classifications(app_user)
  complete_expert_ratings = g$config$complete_experts_ratings


  # ---------------- Admin Server and UI ---------------------------
  if (is_admin) {
    mod_admin_server("admin", app_user)
    admin_panel =
      conditionalPanel(
        "input.admin  == true",
        id = "admin_panel",
        selected = "Upload",
        type = "pills",
        mod_admin_ui("admin")
      )


    insertUI(
      selector = "#main_panel",
      where = "beforeEnd",
      admin_panel
    )
  }

  login_time = Sys.time()
  log_it(glue("Session start user {app_user} at {login_time} "),
         force_console = FALSE)

  add_history_record_if_required(1) # does nothing when not at least 1 hours ago

  # ----------- Allow display of results -----------
  # Display introductory help text in production mode at first starts
  if (g$active_config == "keycloak_production" &&
      !g$config$show_testbuttons &&
      !is_admin &&
      n_classified < 10 )
    delay(2000, ano_modal("readout"))


#  hide("section_value")
  hide("patient_panel")

  insert_user(app_user, app_groups) # Add user name to table

  # -------------------- reactive Values
  rvalues = reactiveValues(
    classification = 0,
    can_save = FALSE,
    can_classify = FALSE, # set by mod_data_server
    cancelled = FALSE,
    finalized = FALSE,
    section_pars = NULL,
    section_line = NULL, # from database
    request_draw_section = 0L,
    window_width = NULL,
    expert_classification = NULL
  )
  if (complete_expert_ratings) {
    rvalues$expert_classification = cleaned_expert_classification_from_database(g$pool)
  }

  # Display message
  if (exists("checked_patients", where = g) && g$checked_patients != "")
    shiny::showNotification(
      HTML(g$checked_patients),
      duration = ifelse(str_starts(g$active_config, "keycloak"), 60, 10),
      closeButton = TRUE,
      type = "warning")


  # ----------- Data Module  ------------------------------
  dm = mod_data_server("dm", app_user, reactive(input$max_p),
                       reactive(input$time_zoom),
                       rvalues )

  # ----------- reactive value window_width ----------------------------
  observe({
    width_step = 20
    rvalues$window_width =
      trunc(session$clientData$output_mainimage_width / width_step)*width_step
  })

  # --------------- enable/disable patient/record well ---------------
  observe({
    shinyjs::toggleState("in_sidebar_well", !input$admin)
  })

  # ----------- classification_method --------------------------------
  classification_method = reactive({
    dm$classification_method()
  })

  # ----------- classification_phase --------------------------------
  classification_phase = reactive({
    dm$classification_phase()
  })

  # ----------- record --------------------------------
  record = reactive({
    dm$record()
  })

  # ----------- markers --------------------------------
  markers = reactive({
    dm$markers()
  })

  # ----------- markers --------------------------------
  active_width = reactive({
    dm$active_width()
  })

  # ----------- protocol_phase_start ------------------------------
  protocol_phase_start = reactive({
    dm$protocol_phase_start()
  })

  # ----------- start_time ------------------------------
  start_time = reactive({
    dm$start_time()
  })

  # ----------- data ------------------------------
  data = reactive({
    dm$data()
  })

  # ----------- Sampling step for this record  --------------------------
  time_step = reactive({
    data()$time_step
  })

  # ----------- update_classification_phase_icons  --------------------------
  update_classification_phase_icons = function(select_all = FALSE){
    dm$update_classification_phase_icons(select_all)
  }

  # ----------- update_classification_phase_icons  --------------------------
  update_record_icons = function(){
    dm$update_record_icons()
  }

  # -------- Enable/disable controls by can_classify
  observe({
    toggleElement("classification", condition = rvalues$can_classify)
    toggleElement( ns_ano("network"), condition = rvalues$can_classify)
    toggleElement("save_panel", condition = rvalues$can_classify)
  })


  # ----------- Save classification --------------------------------
  save_classification = function(finalized = FALSE){
    mk = markers()
    req(mk)
    classification = rvalues$classification
    classification_phase = classification_phase()
    comment = input$comment
    record = record()
    protocol_phase =
      mk[mk$index == as.integer(protocol_phase_start()), "annotation"]
    classification_to_database(app_user, record, classification_method(),
                               finalized, protocol_phase,
                               classification, classification_phase,
                               rvalues$section_pars, comment)
    toggle_button_state(FALSE)
    update_classification_phase_icons(FALSE) # Keep previous settings
    update_record_icons()
    # Must update expert_classifications for x_consensus display
    if (app_user == "x_consensus" && complete_expert_ratings) {
      rvalues$expert_classification = cleaned_expert_classification_from_database(g$pool)
    }

  }

  # ----------- Enable/Disable Save/Cancel/Finalize ---------------
  observeEvent(list(protocol_phase_start(), input$save, input$cancel,
                    classification_phase()), {
                      # Check if needed
                      toggle_button_state(FALSE)
                    })

  # ----------- Save button action ----------------------------------
  observeEvent(input$save, {
    req(rvalues$classification != 0) # Should be Ok anyway
    # TODO isolate classification_method?
    if (classification_method() == 'l' || !is.null(rvalues$section_pars)) {
      save_classification() # Save without asking
    } else {
      shinyWidgets::ask_confirmation("confirm_save",
                       "Confirm save without section",
                       "Do you really want to save without a section view?",
                       btn_labels = c("Go back, will do", "Save anyway"),
                       btn_colors = c("#e08e0b", "#008d4c"))
    }
  })

  # ----------- confirm of save action --------------------------------
  observeEvent(input$confirm_save,{
    if (input$confirm_save) {
      save_classification()
    } else {
      toggle_button_state(TRUE)
    }
    shiny::showNotification("Saved")
  })

  # ----------- Cancel button action --------------------------------
  observeEvent(input$cancel, {
    shiny::showNotification("Cancelled")
    clear_all(TRUE)
    visNetworkProxy(ns_ano("network")) %>%
      visSelectNodes(NULL, clickEvent = TRUE)
    rvalues$classification = 0 # Mark that nothing is selected
    rvalues$cancelled = TRUE # Forces reload
  })

  # ----------- Finalize button action -----------------------------
  observeEvent(input$finalize, {
    no_profile = ""
    # TODO Isolate?
    if (classification_method() == 'h' && is.null(rvalues$section_pars))
      no_profile =
        "<p style='color:red'>It would be nice if you could provide a section view.</p>"
    shinyWidgets::ask_confirmation(inputId = "confirm_finalize",
     title = "Confirm Finalization",
     text = HTML(paste0(no_profile,
    "After finalization you can no longer change your selection.",
    "Trainees will be shown expert classification on the edge text")),
                     btn_labels = c( "I will think it over", "Finalize!"),
                     btn_colors = c( "#e08e0b", "#000000"),
                     html = TRUE
    )
  })

  # ----------- confirm of finalize action -----------------------------
  observeEvent(input$confirm_finalize, {
    if (input$confirm_finalize) {
      save_classification(TRUE)
      rvalues$finalized = TRUE
      shiny::showNotification("Finalized")
    } else {
      toggle_button_state(TRUE)
    }
  })

  # ----------- Readout hrm  ---------------
  output$readout_hrm_value = renderText({
    req(data())
    mc = input$mouse_move
    req(mc)
    dt = as.matrix(data()$data)
    ix = mc$x + 1 + start_time()
    iy = min(max(mc$y, 1), nrow(dt))
    dm = dim(dt)
    if (ix <= 0 || ix > dm[1] || iy <= 0 || iy > dm[2] )
      return('--')
    y = round(y_to_pos(mc$y))
    p = round(dt[ix, iy]/10.0)
    if (y >= 0)
      return(glue(" {p} mmHg {y} mm")) else
    return('--')
  })


  # ----------- Readout conventional  ---------------
  output$readout_conventional_value = renderTable({
    req(data())
    mc = input$mouse_move2
    req(mc)
    dt = as.matrix(data()$data)
    channels = line_channels()
    ix = mc$x + 1 + start_time()
    from_x = max(ix - mc$fill_range ,1)
    to_x = min(ix + mc$fill_range , nrow(dt))
    mx = map_int(channels, ~ as.integer(round((max(dt[from_x:to_x, .])/10))))
    pos = round(y_to_pos(channels))
    pos[1] = "balloon"
    tibble(pos = pos , p = as.integer(round(dt[ix, channels]/10)),
           max = mx)
  },
    striped = TRUE,
    width = "80%",
    align =  "r",
    caption = "max: Maximum in gray range"
  )

  # ----------- js event handlers ----------------------------
  onclick("canvas1", function(event) js$image_clicked(event))
  onevent("mousemove", "canvas1", function(event) {js$mouse_move(event)},
          properties = c("offsetX", "offsetY"))
  onevent("mousemove", "canvas2", function(event) {js$mouse_move2(event)},
          properties = c("offsetX", "offsetY"))
  onevent("dblclick", "canvas1", function(event) clear_all(TRUE) )

  # ------------- Key handler -------------------------------
  observeEvent(input$keys, {
    ck = input$keys
    if (ck == "left")  {
      shinyjs::click(ns_dm("back"))
    } else if (ck == "right") {
      shinyjs::click(ns_dm("forward"))
    } else if (ck == "esc" && !rvalues$finalized) {
      clear_all(TRUE)
    } else if (ck == "+") {
      tz = input$time_zoom
      req(tz != 4)
      tz_next = case_when(
        tz == 1 ~ 2,
        tz == 2 ~ 4
      )
      shinyWidgets::updateSliderTextInput(session, "time_zoom", selected = tz_next)
    } else if (ck == '-') {
      tz = input$time_zoom
      req(tz != 1)
      tz_next = case_when(
        tz == 4 ~ 2,
        tz == 2 ~ 1
      )
      shinyWidgets::updateSliderTextInput(session, "time_zoom", selected = tz_next)
    }
  })

  # ----------- comment_changed ------------------------
  observe({
    if (!is.null(input$comment_changed))
      toggle_button_state(TRUE)
  })

  # ------------ Show section panel -------------------------------
  observeEvent(rvalues$section_pars,{
    showElement("section_value")
  })

  # ----------- Clear sections -------------------------------------
  clear_all = function(clear_section = FALSE) {
    js$clear_all()
    if (clear_section) {
      rvalues$section_pars = NULL
      rvalues$section_line = NULL
    }
  }

  # ----------- Section line output ------------------------
  output$section_value = renderTable({
    req(rvalues$section_pars)
    rv = rvalues$section_pars[1:5,]
    # Only show most important parameters in table
    req(rv)
    if (rv[rv$name == "duration", "value"] == 0) {
      use = 2:5
    }
    else if (rv[rv$name == "length", "value"] == 0) {
      use = c(1,3:5)
    } else {
      use = 1:5
    }
    xtable::xtable(rv[use,])
  }, striped = TRUE, spacing = "s", colnames = FALSE, digits = 0
  )

  # ----------- render section plot---------------------------------------
  output$section = renderPlot({
    # input$section is defined in lines.js
    p = input$section
    if (is.null(p) ||
        is.null(p$x1) ||
        with(p, abs(x1 - x2) < 10 && abs(y1 - y2) < 10 )) {
      hide("section_value")
      return(invisible(NULL))
    }
    rvalues$section_pars = plot_section()
  })

  # ----------- Plot time or position section ----------------------
  plot_section = reactive({
    # input$section is defined in lines.js
    p = input$section
    req(p$x1 > 0 && p$x2 > 0)
    # Check whether time or position plot to be shown
    view = ifelse((with(p, abs((y2 - y1)/(x2 - x1)))) > 4, 2, 1)
    xy = with(p, get_line_xy(
      data()$data,
      start_time(),
      x1,y1, x2, y2, view,
      time_step(),
      input$time_zoom
      )
    )
    if (view == 1) {
      plot_time(xy, input$max_p)
    } else {
      plot_position(xy, input$max_p)
    }
  }) %>%
    bindEvent(input$section,
              input$max_p,
              input$time_zoom,
              protocol_phase_start(),
              classification_phase())

  # ----------- anomanor_file ---------------------------------------
  anomanor_file = reactive({
    req(record())
    mk = markers()
    active_begin = as.integer(protocol_phase_start())
    req(active_begin)
    current_phase_index = which(mk$index == active_begin)
    phase_label = mk$annotation[current_phase_index]
    req(phase_label)
    req(input$time_zoom)
    ww = rvalues$window_width
    js$canvas_resize(ww, g$image_height)
    showElement("patient_panel")

    # TODO: set phase_label as attribute for css
    phase_cache(
      record(),
      classification_method(),
      input$max_p,
      active_begin,
      phase_label,
      active_width(),
      ww,
      input$time_zoom
    )
  })


  # ----------- main image -------------------------------------------
  output$mainimage = renderImage({
    src = anomanor_file()
    req(src)
    if (!is.null(rvalues$section_line) && !is.na(rvalues$section_line$x1))
      rvalues$request_draw_section = isolate(rvalues$request_draw_section) + 1L
    # alt can serve as identifier for cypress e2e testing
    list(src = src, alt = basename(src))
  },
  deleteFile = FALSE
  )

  # ----------- Draw section ----------------------------------------
  observe({
    req(rvalues$request_draw_section > 0)
    req(!is.null(rvalues$section_line))
    st = start_time()
    req(st)
    x1 = as.integer(round(rvalues$section_line$x1 - st, 1))
    x2 = as.integer(round(rvalues$section_line$x2 - st, 1))
    y1 = rvalues$section_line$y1
    y2 = rvalues$section_line$y2
    js$draw_section(x1, y1, x2, y2)
  })

  # ----------- toggle main image state  ------------------------
  enable_main_image = function() {
    js = glue::glue("$('#canvas1').removeClass('noclick')")
    shinyjs::runjs(js)
  }

  disable_main_image = function() {
    js = glue::glue("$('#canvas1').addClass('noclick')")
    shinyjs::runjs(js)
  }

  observe({
    if (rvalues$finalized) {disable_main_image()}  else {enable_main_image()}
    toggleState("comment", !rvalues$finalized)
  })

  # ----------- toggle_picker_state ------------------------------
  toggle_picker_state  = function(id, enabled) {
    # https://github.com/dreamRs/shinyWidgets/issues/341
    disable = ifelse(enabled, "false", "true")
    shinyjs::runjs(glue("$('#{id}').prop('disabled', {disable});"))
    shinyjs::runjs(glue("$('#{id}').selectpicker('refresh');"))
  }

  # ----------- toggle_button_state ------------------------------
  toggle_button_state = function(vs){
    vs = as.logical(vs)
    rvalues$can_save = vs # Needed for todo
    toggleState("save", vs)
    toggleState("cancel", vs)
    shinyWidgets::updateSwitchInput(session, "classification_method", disabled = vs)
    toggle_picker_state("record", !vs)
    toggle_picker_state("classification_phase", !vs)
  }

  # ----------- Finalize button -----------------------------
  observe({
    toggleState("finalize",
                !rvalues$finalized && rvalues$classification != 0 )
  })

  # ----------- Manually added section ------------------------------
  observe({
    # input$section is defined in lines.js
    s = input$section
    req(s, s$user_drawn)
    can_save = (rvalues$classification != 0) && s$user_drawn
    toggle_button_state(can_save)
  })

  # ----------- Selection network ------------------------------
  mod_visnet_server("ano", nodes, edges,
               reactive(classification_phase()),
               reactive(rvalues$finalized))
  # nodes and edges are package internal data from R/sysdata.rda

  # ----------- vis_click ---------------------------------------------
  vis_selected = reactive({
    node = input[[ns_ano("vis_click")]]
    req(protocol_phase_start())
    req(node)
    cp = classification_phase()
    req(cp)
    # nodes are package-internal data
    vis_selected = nodes %>%
      filter(phase == cp)  %>%
      filter(id == node) %>%
      filter(group != 'a')  # only terminal nodes
    ifelse(nrow(vis_selected) == 0, 0, vis_selected$id[1])
  })



  # ----------- when to update network edges ---------------------------
  update_network = reactive({
    req(classification_phase())
    req(rvalues$expert_classification)
    req( (app_groups %in% c("experts", "admins") && g$config$show_results_to_experts) ||
          app_user == 'x_consensus' ||
          (app_groups == "trainees" && rvalues$finalized ))
    list(
         classification_phase(),
         record(),
         input[[ns_ano("network_initialized")]]
    )
  })


  # ----------- update network edges ---------------------------
  observeEvent(update_network(), {
    # edges is internal package global data
    cp = classification_phase()
    cm = classification_method()
    req(cp, cm)
    ed = edges %>%
      filter(phase == cp)
    ec = rvalues$expert_classification %>%
      filter(classification_phase == cp) %>%
      filter(record == str_replace(record(), '.txt', '')) %>%
      filter(method == cm)
    ec = ec |>
      select(consensus_classification, percent, classification)
    ec = ec |>
      left_join(ed, by = c("classification" = "to"))
    req(nrow(ec) > 0)
    max_percent =  suppressWarnings(max(ec$percent, na.rm = TRUE))
    if (max_percent == -Inf) max_percent = 100
    ec = ec %>%
      mutate(
        label = glue("{label}\n{percent}%" ),
        color = case_when(
          consensus_classification == classification ~ "green",
          percent == max_percent ~ "orange",
          TRUE ~ "darkgray"),
        width = if_else(
          consensus_classification == classification, 9,
          percent/12 + 1)
      )  %>%
      select(id, label, color, width)#
    # This delay should be replaced by a completion event
    delay(10,
      visNetworkProxy(ns_ano("network")) %>%
        visUpdateEdges(ec)
    )
  })

  observeEvent(rvalues$classification, {
    sel = if (rvalues$classification == 0) list() else rvalues$classification;
    # There was a 2 ms delay required in earlier versions.
    visNetworkProxy(ns_ano("network")) %>%
      visSelectNodes(sel, clickEvent = TRUE)
  })

  # ----------- Click event vis ------------------------------------
  observe({
    vs = vis_selected()
    toggle_button_state(vs) #  do not convert to logical
    rvalues$classification = vs # Make it public
  })

  # ----------- Login ------------------------------
  output$login = renderImage({
    list(src = "www/login.png")}, deleteFile = FALSE
  )

  # ----------- Help-related functions --------------------

  observeEvent(input$help_about, {
    ano_modal("about")
  })

  # ----------- Legend text --------------------
  output$legend_text = renderUI({
    req(update_network())
    HTML('<small>Arrows<small> Percentages: expert classifications. <span style="color:orange">Orange:</span>majority. <span style="color:green">Green:</span> consensus if available</small></small>')
  })

  # ----------- Patient text --------------------
  output$patient_text = renderUI({
    req(record())
    pat = str_replace(record(), ".txt", "")
    patient_md = glue("{g$patients_dir}/{pat}.md")
    if (!file.exists(patient_md))
      return(glue("No patient file found for '{pat}'"))
    HTML(includeMarkdown(patient_md))
  })

  # ----------- stored_classification --------------------
  stored_classification = reactive({
    classification_from_database(
      app_user, record(), classification_method(),
      classification_phase(), time_step())
  }) %>%
    bindEvent(
      input$max_p,
      protocol_phase_start(),
      classification_phase(),
      classification_method(),
      rvalues$cancelled, # force re-read on cancel
      ignoreInit = FALSE
    )

  # ----------- Retrieve stored ------------------------------------------
  # When record or phase changed, or cancel clicked, get data from database
  observe({
    req(classification_phase() != 'all')
    rvalues$classification = 0 # Protect against transitory invalid
    rvalues$finalized = FALSE # Protect against priority call problems
    cf = stored_classification()
    if (!is.null(cf)) {
      rvalues$finalized = cf$finalized
      rvalues$section_line = cf[1:4]
      updateTextAreaInput(session, "comment", value = cf$comment)
      rvalues$classification = cf$classification
    } else {
#      rvalues$finalized = FALSE
      rvalues$classification = 0 # Nothing selected
      rvalues$section_line = NULL
      rvalues$section_pars = NULL
      clear_all(TRUE)
      updateTextAreaInput(session, "comment", value = NA)
    }
    rvalues$cancelled = FALSE
  })

  observeEvent(input$time_zoom, {
    clear_all(TRUE)
  })

  # ----------- User handling ----------------------
  output$is_admin = reactive({
    is_admin
  })

  # ----------- Make sure generate button is not visible in production
  # is_admin/testbuttons are not visible
  outputOptions(output, 'is_admin', suspendWhenHidden = FALSE)

  output$user = renderText({
    record()
    ag = paste(app_groups, collapse = ", ")
    indocker = ifelse(g$in_docker, 'D', 'ND')
    use_keycloak = ifelse(keycloak_available(), 'K', 'NK')
    if (g$active_config == "keycloak_production" && !is_admin) {
      glue("User: {app_user}/{ag}")
    } else {
      xr = if (complete_expert_ratings)
        {"Expert ratings complete"} else
        "Expert ratings not complete"
      glue("User: {app_user}/{ag} {indocker} {g$active_config}/{use_keycloak}; {xr}")
    }
  })

  # classification_method() with ignoreInit
  observeEvent(classification_method(), {
    is_example = is_example(isolate(record()))
    msg = if (is_example)
      {"For example records starting with <b>$ex</b>, switching between methods shows the same patient's data."} else {
      "Switching between methods displays <b>a different</b> random record." }
    shiny::showNotification(type = "warning", duration = 4, HTML(msg)
    )},
    ignoreInit = TRUE
  )

  # Second listener for classification_method() does not ignoreInit
  observe({
    mp = isolate(input$max_p)
    # TODO: Check if can be moved to mod_data_server
    # TODO: Remove update_classification_phase_icons export if so
    update_classification_phase_icons()
    if (classification_method() == 'l') { # conventional
      hideElement("section_value")
      hideElement("readout_section_value")
      hideElement("readout_hrm_value")
      hideElement("section")
      showElement("readout_conventional_value")
      enable_main_image()
      shinyWidgets::updateSliderTextInput(session, inputId = "max_p",
                            label = "Pressure scale",
                            selected = max_p_hrm,
                            choices = g$pressure_choices)
      max_p_line <<- mp

    } else {
      showElement("section_value")
      showElement("readout_section_value")
      showElement("readout_hrm_value")
      showElement("section")
      hideElement("readout_conventional_value")
      enable_main_image()
      shinyWidgets::updateSliderTextInput(session, inputId = "max_p",
                            label = "Maximal pressure",
                            selected = max_p_line,
                            choices = g$pressure_choices)
      max_p_hrm <<- mp
    }
  }
  )

  output$canvas = renderUI({
    cm = classification_method()
    req(cm)
    cv = ifelse(cm == 'l', 2, 1)
    ww = isolate(rvalues$window_width)
    HTML(glue('<canvas id="canvas{cv}" width="{ww}px",
              " height="{g$image_height}px"></canvas>'))
  })

  onRestored(function(state){
#    http://127.0.0.1:4848/?_inputs_&dm-record=%22430511_ib.txt%22&dm-classification_method=true&dm-classification_phase=%22tone%22
    record_restore = isolate(state$input$`dm-record`)
    # TODO This  flickers!
    shinyWidgets::updatePickerInput(session, "dm-record", selected = record_restore)
  })


  session$onSessionEnded(function() {
    in_session_time = Sys.time() - login_time
    log_it(
      glue("Session ended user {app_user} after {round(in_session_time,1)} ",
           "{attr(in_session_time,'units')}"),
           force_console = FALSE)
    if (keycloak_available())
      g$keycloak$logout_user_by_name(app_user)
#    stopApp() # this will crash the app on F5
  })
}
