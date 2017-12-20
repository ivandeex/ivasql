SELECT * from pg_collation where lower(collname) like '%ru%';
SELECT * from pg_database;

DROP COLLATION IF EXISTS pg_catalog."en_US";
CREATE COLLATION pg_catalog."en_US" (LC_COLLATE='English_United States.1252', LC_CTYPE='English_United States.1252');
DROP COLLATION IF EXISTS pg_catalog."ru_RU";
CREATE COLLATION pg_catalog."ru_RU" (LC_COLLATE='Russian_Russia.1251', LC_CTYPE='Russian_Russia.1251');
DROP COLLATION IF EXISTS pg_catalog."ru_ICU";
CREATE COLLATION pg_catalog."ru_ICU" (provider=icu, locale='ru');
DROP COLLATION IF EXISTS pg_catalog."ru_ICU_upperfirst";
CREATE COLLATION pg_catalog."ru_ICU_upperfirst" (provider=icu, locale='ru@-u-kf-upper');

INSERT INTO rus VALUES ('Joao'),('João');
SELECT * FROM rus ORDER BY a COLLATE "en_US";
SELECT * FROM rus ORDER BY a COLLATE "ru_RU";
SELECT * FROM rus ORDER BY a COLLATE "ru_ICU";
SELECT * FROM rus ORDER BY a COLLATE "ru_ICU_upperfirst";
SELECT * FROM rus ORDER BY a COLLATE "und-x-icu";
SELECT * FROM rus ORDER BY a COLLATE "ucs_basic";

DELETE FROM rus WHERE a = 'Joao';
SELECT unaccent('Œ Æ œ æ ß' COLLATE "ru_RU");
SELECT unaccent('Œ' COLLATE "en_US") ILIKE 'oe';
SELECT unaccent('Œ' COLLATE "ru_RU") ILIKE 'oe';
