SELECT * FROM pg_database;
SELECT * FROM pg_collation;

UPDATE pg_database SET datistemplate=FALSE WHERE datname='template1';
DROP DATABASE template1;
CREATE DATABASE template1 ENCODING = 'UTF8' LC_COLLATE='Russian_Russia' LC_CTYPE='Russian_Russia' TEMPLATE template0; 
--CREATE DATABASE template1 ENCODING = 'UTF8' TEMPLATE template0; 
UPDATE pg_database SET datistemplate=TRUE WHERE datname='template1';

DROP DATABASE IF EXISTS test;
CREATE DATABASE test;
