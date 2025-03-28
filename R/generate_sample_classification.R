#' Generates sample classification
#'
#' @param users List of user names
#' @param force Force confirm in keykloak if active
#' @param expert_complete Make expert classifications complete to show feedback for
#' trainees
#' @param add_consensus Add consensus user `x_consensus` as sample
#'
#' @return Logged text if successful. As main side effect, database
#' is cleared, and users with sample classifications are added.
#' @export
generate_sample_classification = function(users, force = TRUE,
                            expert_complete = FALSE, add_consensus = FALSE){
  stopifnot(is.list(g)) # Globals
  if (!force) {
    us = dbGetQuery(g$pool, "SELECT distinct user from classification")$user
    if (all(users %in% us)) return("Test run: Sample data not overwritten")
  }
  # Add edges from excel sheet nodes_edges.xlsx
  c(nodes, edges) %<-% nodes_edges(g$pool)

  # Remove old
  dbExecute(g$pool, "DELETE FROM classification")

  set.seed(4711)
  p_correct = 0.7 # Probability of correct choices
  p_finalized = 0.7 # Probability of finalized
  p_missing = 0.2
  p_no_section = 0.3
  # nodes are package-internal data
  end_nodes = nodes %>%
    filter(group != "a") %>%
    select(phase, id)
  # Generate one test record
  q = "update record set anon_h= '$ex1', anon_l = '$ex1' where record = 1"
  dbExecute(g$pool, q)

  q = "SELECT record from record where valid = 1"
  records = dbGetQuery(g$pool, q)$record
  phases = unique(end_nodes$phase)
  dbExecute(g$pool,"PRAGMA foreign_keys=ON")
  q = glue_sql("DELETE from user", .con = g$pool)
  dbExecute(g$pool, q)
  # Add consensus user if required
  add_users = users
  if (add_consensus) add_users = c(add_users, "x_consensus")
  lapply(add_users, function(user){
    group = ifelse(str_starts(user, "x_"), "experts", "trainees")
    insert_user(user, group)
    invisible(NULL)
  })
  for (record in records) {
    for (phase1 in phases) {
      classes = (end_nodes %>% filter(phase == phase1))$id
      correct_class = sample(classes, 1)
      if (add_consensus) {
        classification_to_database(
          user = "x_consensus", record, 'h', 1, "begin",
                   correct_class, phase1, NULL, "Consensus")
      }
      for (user in users) {
        is_expert = str_starts(user, "x_")
        if (!(is_expert && expert_complete) && rbinom(1,1, p_missing) != 0)
          next
        for (method in c("l", "h")) {
          use_correct = rbinom(1, 1,  p_correct)
          classification = ifelse(use_correct, correct_class, sample(classes, 1))
          tt = round(rnorm(1, 30, 5),1)
          pos = round(rnorm(1, 27, 5),1)
          section_pars = NULL
          has_section =  method == 'h' && rbinom(1,1, p_no_section) == 0
          if (has_section) {
            section_pars = tribble(
              ~name, ~value,
              "duration", 0,
              "length", round(rnorm(1, 27, 2),1),
              "p_min",  round(rnorm(1, 0),1),
              "p_max",  round(rnorm(1, 100, 20),1),
              "above_base", round(rnorm(1, 100, 20),1),
              "t1", tt,
              "t2", tt,
              "pos1", pos,
              "pos2", round(pos + rnorm(1, 5),1)
            )
          }
          finalized = ifelse(is_expert, 1, rbinom(1, 1,  p_finalized))

          classification_to_database(user, record, method, finalized, "begin",
                                 classification, phase1, section_pars, "Comment")
        } # method
      } # user
    }  # phase
  } # record

  dbExecute(g$pool, "DELETE FROM ano_logs")
  if (is.null(g$keycloak) || !g$keycloak$active()) {
    ret = "Generated sample data without keycloak"
    log_it(ret)
    return(ret)
  }
  # Add to keycloak if not there already
  for (user in users) {
    group = ifelse(str_starts(user, "x_"), "experts", "trainees")
    email = glue("{user}@{g$config$test_email_url}")
    p = g$keycloak$add_user(email, group, force_confirm = TRUE, emailVerified = TRUE)
#      log_it(paste0(p, " ", email, " ", group, "\n"))
  }
}


