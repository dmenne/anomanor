classification_record_all = function() {
q = "select anon.record, anon.method, anon.anon, cnt.n_ratings
from (
select record, 'l' as method, anon_l as anon  from record
  union
  select record, 'h' as method, anon_h as anon from record)
 as anon
left join (
select r.record, c.method, count(c.classification) as n_ratings
from record r
left join classification c
on c.record = r.record
where r.valid = 1
group by r.record, c.method
) as cnt
on cnt.record = anon.record and cnt.method = anon.method
order by anon.record, anon.method"
  dbGetQuery(g$pool, q) %>%
    as_tibble()
}

