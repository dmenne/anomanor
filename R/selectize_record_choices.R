selectize_record_choices = function(record_summary ) {
  choices = list()
  icon = NULL
  todo0 = record_summary[is.na(record_summary$nfinalized), ]
  todo = setNames(paste0(todo0$record, ".txt"), todo0$anon)
  rs = na.omit(record_summary)
  partial0 = rs[rs$nfinalized %in% 0:2, ]
  partial = setNames(paste0(partial0$record, ".txt"), partial0$anon)

  finalized0 = rs[rs$nfinalized == 3, ]
  finalized = setNames(paste0(finalized0$record, ".txt"), finalized0$anon)

  if (nrow(partial0) > 0) {
    choices = c(choices, Partial = list(partial))
    icon = partial0$icon
  }
  if (nrow(todo0) > 0) {
    choices = c(choices, ToDo = list(todo))
    icon = c(icon, todo0$icon)
  }
  if (nrow(finalized0) > 0) {
    choices = c(choices, Finalized = list(finalized))
    icon = c(icon, finalized0$icon)
  }
  list(choices = choices, icon = icon)
}