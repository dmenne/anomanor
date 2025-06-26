select distinct substring(row_id, 1, INSTR(row_id, '_') - 1) as tablename_v1, key as key_v1 from v1;
select distinct substring(row_id, 1, INSTR(row_id, '_') - 1) as tablename_v2, key as key_v2 from v2;

