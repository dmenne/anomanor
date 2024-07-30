library(testthat)
options(Ncpus = parallel::detectCores(logical = TRUE))
# Some tests may fail in parallel mode.
# Use in DESCRIPTION
# Config/testthat/parallel: true
#options(Ncpus = 1)
test_check("anomanor")
