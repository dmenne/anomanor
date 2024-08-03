get_settings = function(user, key){
  sql = glue_sql("SELECT value FROM settings where user = {user} ",
                 "AND key = {key}",
                 .con = g$pool)
  ret = dbGetQuery(g$pool, sql)
  ifelse(length(ret) == 0, NA_character_, ret$value)
}

save_settings = function(user, key, value){
  sql = glue_sql("INSERT  OR REPLACE INTO settings (user, key, value) ",
  "VALUES({user}, {key}, {value})", .con = g$pool)
  dbExecute(g$pool, sql)
}

get_finalize_count = function(user){
  ret = get_settings(user, "finalize_count")
  ifelse(is.na(ret), 0, as.integer(ret))
}

increment_finalize_count = function(user, count){
  count = count + 1L
  tryCatch(
    {
      save_settings(user, "finalize_count", count)
      as.integer(count)
    },
    error = function(err) {
      NA
    }
  )
}


