SELECT r.record, classification_phase, method, consensus_classification, anon_h, anon_l
from cleaned_expert_classification c
left join record r
on c.record = r.record
where c.percent is NULL

