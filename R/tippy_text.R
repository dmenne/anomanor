tippy_main_text = tibble::tribble(
  ~id, ~text,
  "save", "Save temporarily.<br><small>Use <b>Finalize</b> when you are sure you do not plan later edits</small>",
  "cancel", "Cancel classification",
  "finalize", "Save and make read-only.<br><small>After finalization, trainees will be shown expert classification choices and consensus result.</small>"
)

# Use tippy directly in ui for selectize boxes
tippy_all = function() {
  invisible(apply(tippy_main_text, 1, function(x) tippyThis(x["id"], x["text"])))
}

