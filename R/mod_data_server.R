mod_data_server = function(id,  app_user, max_p, time_zoom, rvalues) {
  stopifnot(
    is.character(id),
    !is.reactive(app_user),
    is.reactive(max_p),
    is.reactive(time_zoom),
    is.reactivevalues(rvalues)
  )

  moduleServer(
    id,
    function(input, output, session) {
      new_marker_x = NULL

      # ----------- classification_method --------------------------------
      classification_method = reactive({
        if_else(input$classification_method, 'l', 'h')
      })

      # ----------- Data on record change -----------------------------------------
      data = reactive({
        rec = input$record
        req(rec)
        cf = record_cache(rec, max_p(), time_zoom())$cache_file
        req(file.exists(cf))
        readRDS(cf)
      })

      # ----------- Next phase of record ---------------
      observeEvent(input$forward, {
        mk = markers()
        req(input$protocol_phase_start)
        req(mk)
        rvalues$request_clear = TRUE
        next_phase = mk$index[next_phase_index(mk)]
        updateSelectizeInput(session, "protocol_phase_start", selected = next_phase)
      })

      # ----------- Previous phase of record -------------------------------
      observeEvent(input$back, {
        mk = markers()
        req(mk)
        req(input$protocol_phase_start)
        rvalues$request_clear = TRUE
        previous_phase = mk$index[previous_phase_index(mk)]
        req(previous_phase) # Do nothing on null
        updateSelectizeInput(session, "protocol_phase_start", selected = previous_phase)
      })


      # ----------- records -----------------------------
      records = reactive({
        input$classification_phase
        input$record
        rvalues$finalized
        classification_record_summary(app_user, classification_method())
      })

      # ----------- Record dropdown items --------------------------
      observeEvent(records(),{
        update_record_icons()
      })

      # ----------- Update record items function ---------------------
      update_record_icons = function(){
        crs = records()
        req(crs)
        ncompleted = sum(crs$nfinalized, na.rm = TRUE)
        ntotal = nrow(crs)*3
        shinyWidgets::updateProgressBar(
          session,
          id = "completed",
          value = ncompleted,
          total = ntotal,
          status = ifelse(ncompleted == ntotal, "success", "primary"))
        choices = selectize_record_choices(crs)
        shinyWidgets::updatePickerInput(
          session = session,
          inputId = "record",
          selected = input$record,
          choices = choices$choices,
          choicesOpt = list(icon = choices$icon)
        )
      }

      # ----------- Width of current marker to next marker -------------------------
      active_width = reactive({
        req(input$record)
        req(input$protocol_phase_start)
        mk = all_markers()
        active_begin = as.integer(input$protocol_phase_start)
        current_phase_index = which(mk$index == active_begin)
        if (length(current_phase_index) == 0) {
          current_phase_index = 1
          active_begin = 0
        }
        next_phase_index = current_phase_index + 1
        if (next_phase_index <= nrow(mk)) {
          width = mk$index[next_phase_index] - active_begin
        } else {
        # TODO: Code smell. time_zoom() was added post hoc and is
        # handled inconsistently
          width = nrow(data()$data)/time_zoom() - active_begin
        }
        width
      })

      # ----------- Classification dropdown icons -----------------------
      update_classification_phase_icons = function(select_all = FALSE) {
        rec = input$record
        ps = classification_phase_summary(app_user,
                                          str_replace(rec, '.txt', ''),
                                          classification_method())
        selected = if (select_all)  "all" else input$classification_phase
        shinyWidgets::updatePickerInput(session = session,
                          inputId = "classification_phase",
                          selected = selected,
                          choices = g$classification_phase_choices,
                          choicesOpt = list(icon = ps$icon))
      }

      # ----------- Icon change observers -----------------------------------
      observeEvent(input$record, {
        update_classification_phase_icons(TRUE) # Switch to "all"
      })


      # ----------- Markers ---------------------------------
      all_markers = eventReactive(input$record, {
        classification_method()
        rec = input$record
        req(rec)
        mk = markers_for_record(rec)
      })

      markers = reactive({
        classification_method()
        rec = input$record
        new_marker_x <<- NA
        req(rec)
        mk = markers_for_record(rec)
        mk = filter_markers(mk, input$classification_phase)
        # Report this to caller
        rvalues$can_classify = input$classification_phase != 'all'
        req(nrow(mk) > 0)
        # When there are markers
        marker_choices = setNames(mk$index, mk$annotation)
        updateSelectizeInput(session, "protocol_phase_start", choices = marker_choices)
        mk
      })

      # ----------- Display start time relative to record ---------------------
      start_time = reactive({
        req(input$protocol_phase_start)
        input$classification_phase
        active_begin = as.integer(input$protocol_phase_start)*time_zoom()
        image_width = nrow(data()$data)
        isolate(record_start_time(active_begin, active_width()*time_zoom(),
                                  rvalues$window_width, image_width) )
      })

      # ----------- Navigation auxiliary function -------------------------------
      next_phase_index = function(mk) {
        if (nrow(mk) < 1) return(NULL)
        phase_index = as.integer(isolate(input$protocol_phase_start))
        new_phase_index = which.min(abs(mk$index - phase_index)) + 1
        if (new_phase_index > nrow(mk) ) {
          if (nrow(mk) > 1)
            shiny::showNotification("Jumped back", duration = 2)
          new_phase_index = 1
        }
        new_phase_index
      }

      previous_phase_index = function(mk) {
        if (nrow(mk) < 1) return(NULL)
        phase_index = as.integer(isolate(input$protocol_phase_start))
        new_phase_index = which.min(abs(mk$index - phase_index)) - 1
        if (new_phase_index < 1) {
          if (nrow(mk) > 1)
            shiny::showNotification("Jumped to last", duration = 2)
          new_phase_index = nrow(mk)
        }
        new_phase_index
      }

      # ----------- Save/cancel/finalize comment ---------------------------
      output$todo = reactive( {
        if (rvalues$finalized)
          return('Finalized<br><img src = "www/finalized.png"/>')
        if (!is.null(input$classification_phase) && input$classification_phase == 'all')
          return('<img src = "www/arrow.png"><br>Select phase')
        if (rvalues$classification == 0)
          return('Select classification<br><img src = "www/classification.png"/>')
        if (!rvalues$can_save)
          return('Modify saved<br><img src = "www/classification.png"/>')
        if (!is.null(rvalues$section_pars))
          return('Save, Cancel, Finalize<br><img src = "www/save_cancel.png" />')

        'Add section<br><img src = "www/section.png"><br>'
      })

      observeEvent(input$help, {
        ano_modal("readout")
      })

      observeEvent(input$london_classification, {
        cp = input$classification_phase
        part = case_when(
          cp == "rair" ~ "1",
          cp == "tone" ~ "2",
          cp == "coord" ~ "3",
          TRUE ~ "all"
        )
        ano_modal(glue("part{part}"))
      })

      # return values
      list(
        classification_method = classification_method,
        record = reactive(input$record),
        classification_phase = reactive(input$classification_phase),
        protocol_phase_start = reactive(input$protocol_phase_start),
        update_classification_phase_icons = update_classification_phase_icons,
        update_record_icons = update_record_icons,
        active_width = active_width,
        start_time = start_time,
        data = data,
        records = records,
        markers = markers
      )
    })
}

