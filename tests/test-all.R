library(testthat)
# Use in DESCRIPTION
# Config/testthat/parallel: true
options(Ncpus = parallel::detectCores(logical = TRUE))
# Some tests may fail in parallel mode.
#options(Ncpus = 6)
test_check("anomanor")
