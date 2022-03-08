#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector rev_limit(NumericVector x, double min, double max) {
  for (R_xlen_t i = 0; i< x.size(); i++)
    x[i] = std::max(std::min(x[i], max), min);
  std::reverse(x.begin(), x.end());
  return x;
}


/*** R
rev_limit(1:10, 2, 8)
*/
