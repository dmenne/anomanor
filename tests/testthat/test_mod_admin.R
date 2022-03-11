Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())
library(shiny)

test_that("Can create admin server", {

  shiny::testServer(mod_admin_server, args = list(), expr = {
    request_usertable = TRUE
    dt = user_stats_table()
    expect_gte(nrow(dt), 10)
    expect_equal(ncol(dt), 8)
    expect_equal(names(dt),
                c("user", "email", "name", "verified", "group",
                  "method", "saved", "finalized"))
  })

})
