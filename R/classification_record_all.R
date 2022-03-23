classification_record_all = function() {
q = "select r.record, c.method, t.anon, count(c.classification) as n_ratings
from record r
left join classification c
on c.record = r.record
left join (
select record, 'l' as method, anon_l as anon  from record
  union
  select record, 'h' as method, anon_h as anon from record) as t
on t.method = c.method and t.record = r.record
where r.valid = 1
group by r.record, c.method"
  dbGetQuery(g$pool, q) %>%
    as_tibble()
}

