select * from mail_messages order by sent limit 1;
alter table mail_messages add column tsv tsvector;
update mail_messages set tsv = to_tsvector(subject||' '||author||' '||body_plain);
create index on mail_messages using gist(tsv);
vacuum mail_messages;
analyze mail_messages;
select * from mail_messages where tsv @@ to_tsquery('magic & value');
explain analyze
select * from mail_messages where tsv @@ to_tsquery('magic & value')
order by tsv;




