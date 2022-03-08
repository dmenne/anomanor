insert_user = function(user, group) {
  q = glue_sql(
    "INSERT INTO user (user, [group]) VALUES({user}, {group}) ",
    "ON CONFLICT(user) DO UPDATE SET [group]=excluded.[group] ",
    "WHERE excluded.[group] <> user.[group]",
    .con = g$pool)
  ret = dbExecute(g$pool, q)
  if (ret == 1)
    log_it(glue("Inserted or updated user {user}/{group}"))
}

