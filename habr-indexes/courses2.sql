select mode, granted from pg_locks where relation = 't2'::regclass;

select relation::regclass, mode, granted from pg_locks;

select indexrelid::regclass index_name, indrelid::regclass table_name, indisvalid
from pg_index where indrelid::regclass::text like 't%';
