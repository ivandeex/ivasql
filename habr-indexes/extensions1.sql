create extension pg_variables;
create extension pageinspect;
create extension postgres_fdw;
create extension jsquery;

select xmin,xmax,* from t2 order by xmin::text::int desc limit 5;
select txid_current();
select * from page_header(get_raw_page('t2','main',4));

select * from pgv_list() order by package, name;
select pgv_set_text('iva','fio','Ivan Andreev');
select pgv_get_text('iva','fio');
select pgv_free();

