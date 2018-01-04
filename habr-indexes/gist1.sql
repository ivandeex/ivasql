-- R-дерево для точек
create table points(p point);
insert into points(p) values
  (point '(1,1)'), (point '(3,2)'), (point '(6,3)'),
  (point '(5,5)'), (point '(7,8)'), (point '(8,6)');
drop index if exists points_p_idx;
create index on points using gist(p);
set enable_seqscan to off;
select * from points;
-- k-NN — k-nearest neighbor search:
select * from points order by p <-> point '(4,7)' limit 2;

-- R-дерево для интервалов
drop table if exists reservations;
create table reservations(during tsrange);
insert into reservations(during) values
  ('[2016-12-30, 2017-01-09)'),
  ('[2017-02-23, 2017-02-27)'),
  ('[2017-04-29, 2017-05-02)');
drop index if exists reservations_during_ix;
create index reservations_during_ix on reservations using gist(during);
select * from reservations where during && '[2017-01-01, 2017-04-01)';

alter table reservations add exclude using gist(during with &&);
insert into reservations(during) values ('[2017-06-10, 2017-06-13)');
insert into reservations(during) values ('[2017-05-15, 2017-06-15)'); -- fails

alter table reservations add house_no integer default 1;
alter table reservations drop constraint reservations_during_excl;
alter table reservations add exclude using gist(during with &&, house_no with =);
create extension btree_gist;

insert into reservations(during, house_no) values ('[2017-05-15, 2017-06-15)', 1); -- fails
insert into reservations(during, house_no) values ('[2017-05-15, 2017-06-15)', 2); -- ok

-- полнотекстовый поиск
set default_text_search_config = russian;
select to_tsvector('И встал Айболит, побежал Айболит. По полям, по лесам, по лугам он бежит.');
select to_tsquery('Айболит & (побежал | пошел)');
select to_tsvector('И встал Айболит, побежал Айболит.') @@ to_tsquery('Айболит & (побежал | пошел)');
select to_tsvector('И встал Айболит, побежал Айболит.') @@ to_tsquery('Бармалей & (побежал | пошел)');

-- RD-дерево для полнотекстового поиска
create table ts(doc text, doc_tsv tsvector);
create index on ts using gist(doc_tsv);
insert into ts(doc) values
  ('Во поле береза стояла'),  ('Во поле кудрявая стояла'), ('Люли, люли, стояла'),
  ('Некому березу заломати'), ('Некому кудряву заломати'), ('Люли, люли, заломати'),
  ('Я пойду погуляю'),        ('Белую березу заломаю'),    ('Люли, люли, заломаю');
update ts set doc_tsv = to_tsvector(doc);

-- SPgist-дерево для точек
-- https://habrahabr.ru/company/postgrespro/blog/337502/
create table points(p point);
insert into points(p) values
  (point '(1,1)'), (point '(3,2)'), (point '(6,3)'),
  (point '(5,5)'), (point '(7,8)'), (point '(8,6)');
create index points_quad_idx on points using spgist(p);
set enable_seqscan = off;
select * from points where p >^ point '(2,7)';

select amop.amopopr::regoperator, amop.amopstrategy
from pg_opclass opc
join pg_opfamily opf on opf.oid = opc.opcfamily
join pg_am am on am.oid = opf.opfmethod
join pg_amop amop on amop.amopfamily = opc.opcfamily and amop.amoplefttype = opc.opcintype
where opc.opcname = 'quad_point_ops' and am.amname = 'spgist';
-- <<(point,point) | строго слева
-- >>(point,point) | строго справа
-- ~=(point,point) | совпадает
-- <^(point,point) | строго снизу
-- >^(point,point) | строго сверху
-- <@(point,box)   | содержится в прямоугольнике
create extension pageinspect;
select * from spgist_print('points_quad_idx'::regclass);

create index airports_coordinates_quad_idx
  on airports using spgist(point(latitude,longitude));
select * from spgist_stats('airports_coordinates_quad_idx');

create index points_kd_idx on points using spgist(p kd_point_ops);

-- spgist/radix tree (trie)
create table sites(url text);
insert into sites values ('postgrespro.ru'),('postgrespro.com'),
                         ('postgresql.org'),('planet.postgresql.org');
create index on sites using spgist(url);
-- http://www.evernote.com/l/AEvj6lBKAe9F_o5TdgeIH1vy0qGAmqNyTsw/
select * from sites where url like 'postgresp%ru';
-- операторы с тильдами работают не с символами, а с байтами
select * from sites where url is null;

select amop.amopopr::regoperator, amop.amopstrategy
from pg_opclass opc
join pg_opfamily opf on opf.oid = opc.opcfamily
join pg_am am on am.oid = opf.opfmethod
join pg_amop amop on amop.amopfamily = opc.opcfamily
                  and amop.amoplefttype = opc.opcintype
where opc.opcname = 'text_ops'
  and am.amname = 'spgist';





