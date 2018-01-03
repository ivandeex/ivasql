create extension pageinspect;
select * from bt_metap('t2i');
select "type", live_items, dead_items, avg_item_size, page_size, free_size
       from bt_page_stats('t2i', (select root from bt_metap('t2i')));
select itemoffset, ctid, itemlen, left(data, 56) as data
       from bt_page_items('t2i', (select root from bt_metap('t2i')))
       limit 5;

create extension amcheck;
select bt_index_check('t2i'::regclass);

select oid,relname,relkind,relpages,reltuples,
       pg_size_pretty(pg_total_relation_size(oid)) total,
       pg_size_pretty(pg_relation_size(oid)) relsize,
       pg_size_pretty(pg_table_size(oid)) tabsize
from pg_class order by pg_total_relation_size(oid) desc;
select regclass('t')::text;
