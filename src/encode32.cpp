#include <Rcpp.h>
using namespace Rcpp;

static const std::string base32_chars = "abcdefghijkmnpqrstuvwxyz23456789";

// [[Rcpp::export]]
String encode32(uint32_t hash_int, int length = 7)
{
  String res;
  std::ostringstream oss;
  if (length > 7 || length < 1) 
    length = 7;
  for (int i = 0; i < length; i++) {
    oss << base32_chars[hash_int & 31];
    hash_int = hash_int >> 5;
  }
  res = oss.str();
  return res;
}

