drop table if exists t;
create table t (a integer, b text, c boolean);
insert into t (a, b, c)
  select s.i, chr((32 + random() * 94) :: integer), random() < 0.01
  from generate_series(1, 1000000) as s(i) order by random();

create index on t (a);
analyze t;
select * from t where a = 1;
select * from t where a <= 100;

create index on t(b);
select * from t where a <= 100 and b = 'a';
select * from t where a <= 100 or b = 'a';
select attname, correlation from pg_stats where tablename = 't';

select * from t where a <= 400000;
select * from t where a <= 400000 order by a;
select a from t where a <= 400000 order by a;
select * from t where a <= 300000;

select a from t where a < 100;
vacuum t;
explain analyze select a from t where a < 1000;

select * from university order by country nulls first;
select * from university order by country nulls last;

create index on t(a,b);
analyze t;
select * from t where a <= 100 and b = 'a';
select * from t where a <= 100;

select * from t where lower(b) = 'a';
create index on t(lower(b));
analyze t;
select * from pg_stats where tablename = 't_lower_idx';
--alter index t_lower_idx alter column "lower" set statistics 60;

create index on t(c);
analyze t;
select * from t where c;
select * from pg_stats where tablename like 't_%';
select * from t where not c;
select relpages from pg_class where relname like 't_c_idx%';
create index on t(c) where c;

select * from t order by a;
set enable_indexscan=off;
set enable_indexscan=on;

drop table if exists t2;
create table t2 (a integer, b text, c boolean);
insert into t2 (a, b, c)
  select s.i, chr((32 + random() * 94) :: integer), random() < 0.01
  from generate_series(1, 10000000) as s(i) order by random();
commit;
drop index if exists t2i;
create index t2i on t2(a,b);
create index concurrently t2i on t2(a,b);
select mode, granted from pg_locks where relation = 't2'::regclass;
select pg_size_pretty(pg_total_relation_size('t2'));

create extension pageinspect;
select * from bt_metap('t2i');
select "type", live_items, dead_items, avg_item_size, page_size, free_size
       from bt_page_stats('t2i', (select root from bt_metap('t2i')));
select itemoffset, ctid, itemlen, left(data, 56) as data
       from bt_page_items('t2i', (select root from bt_metap('t2i')))
       limit 5;

vacuum t2;
analyze t2;
select * from pg_class where relname='t2';

create extension amcheck;
select bt_index_check('t2i'::regclass);

select amname from pg_am;
select a.amname, p.name,
       pg_indexam_has_property(a.oid, p.name) has
from pg_am a, unnest(array['can_order','can_unique',
                           'can_multi_col','can_exclude']) p(name)
order by a.amname;

select p.name prop,
       pg_index_has_property('t_a_idx'::regclass, p.name) has
from unnest(array['clusterable','index_scan',
                  'bitmap_scan','backward_scan']) p(name);

select p.name prop,
       pg_index_column_has_property('t_a_idx'::regclass, 1, p.name) has
from unnest(array['asc','desc','nulls_first','nulls_last',
            'orderable','distance_orderable','returnable',
            'search_array','search_nulls']) p(name);

select oid,relname,relkind,relpages,reltuples,
       pg_size_pretty(pg_total_relation_size(oid)) total,
       pg_size_pretty(pg_relation_size(oid)) relsize,
       pg_size_pretty(pg_table_size(oid)) tabsize
from pg_class order by pg_total_relation_size(oid) desc;
select regclass('t')::text;

with t1(name) as (select name from pg_ls_logdir() order by modification desc limit 1),
     t2(file) as (select pg_read_file('log/' || (select name from t1))),
     t3(line) as (select * from regexp_split_to_table((select file from t2), '\n'))
select row_number() over (), line from t3;

select * from pg_get_keywords();

select tableoid,xmin,xmax,cmin,cmax,ctid,* from bar;
select 'bar'::regclass::oid;

show lc_collate;
select b from t where b like 'A%';
create index on t(b text_pattern_ops);

select a.amname, c.opcname, c.opcintype::regtype
from pg_opclass c join pg_am a on c.opcmethod = a.oid
order by a.amname, c.opcintype::regtype::text;

select amop.amopopr::regoperator
from pg_opclass opc, pg_opfamily opf, pg_am am, pg_amop amop
where opc.opcname = 'array_ops'
and opf.oid = opc.opcfamily
and am.oid = opf.opfmethod
and amop.amopfamily = opc.opcfamily
and am.amname = 'btree'
and amop.amoplefttype = opc.opcintype;

drop table t2;
