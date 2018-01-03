select distinct flight_no from flights order by 1;
select * from flights where flight_no = 'PG0494';
drop index if exists flights_flight_no_hash_ix;
create index flights_flight_no_hash_ix on flights using hash(flight_no);

set enable_seqscan = off;
set enable_seqscan = on;
select * from aircrafts;
select * from aircrafts where range = 3000;
select * from aircrafts where range < 3000;
select * from aircrafts where range between 3000 and 5000;

drop index aircrafts_range_idx;
create index aircrafts_range_idx on aircrafts(range desc);

create or replace view aircrafts_v as
select model, case when range < 4000 then 1
                   when range < 10000 then 2
                   else 3
              end as class
from aircrafts;

select * from aircrafts_v;

create index aircrafts_v_ix1 on aircrafts(
  (case when range < 4000 then 1 when range < 10000 then 2 else 3 end),
  model);
select class, model from aircrafts_v order by class, model;
select class, model from aircrafts_v order by class desc, model desc;
select class, model from aircrafts_v order by class asc, model desc;
create index aircrafts_case_asc_model_desc_idx on aircrafts(
  (case when range < 4000 then 1
        when range < 10000 then 2
        else 3 end) asc,
  model desc);

select * from flights where actual_arrival is null;
create index on flights(actual_arrival);
select * from flights order by actual_arrival nulls last;
select * from flights order by actual_arrival nulls first;
create index flights_nulls_first_idx on flights(actual_arrival nulls first);

\pset null NULL;
select null < 42;

select * from aircrafts where aircraft_code in ('733','763','773');

select to_hex(magic), * from bt_metap('ticket_flights_pkey');
create extension pageinspect;

create extension gevel;
select * from gist_stat('airports_coordinates_idx');




