# https://github.com/r-lib/covr/issues/448#issuecomment-797738022
options(covr.gcov =  "C:/rtools40/mingw64/bin/gcov.exe")
cov = covr::package_coverage(line_exclusions = c(
  "R/run_app.R",
  "R/app_config.R"
#  "R/keycloak.R"
) )
covr::report(cov, file = "./covr/coverage-report.html")
