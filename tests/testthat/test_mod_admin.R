Sys.setenv("R_CONFIG_ACTIVE" = "test")
globals()
withr::defer(cleanup_test_data())
library(shiny)

test_that("Can show user table", {
  shiny::testServer(mod_admin_server, args = list(app_user = "sa_admin"), expr = {
    request_usertable = TRUE
    dt = user_table()
    expect_gte(nrow(dt), 10)
    expect_equal(ncol(dt), 8)
    expect_equal(names(dt),
                c("user", "email", "name", "verified", "group",
                  "method", "saved", "finalized"))
  })
})

test_that("Can show record summary table", {
  shiny::testServer(mod_admin_server, args = list(app_user = "sa_admin"), expr = {
    session$setInputs(refresh_statistics = 2)
    dt = record_summary_table()
    expect_s3_class(dt, "tbl")
    expect_equal(names(dt), c("record", "method", "anon", "n_ratings"))
    expect_equal(nrow(dt), 4)
    expect_equal(unique(dt$record), c("test1", "test2"))
  })
})

})

