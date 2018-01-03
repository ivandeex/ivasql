select hashtext('раз') AS dec,
       ('x' || lpad(to_hex(hashtext('раз')),8,'0')) AS hex,
       ('x' || lpad(to_hex(hashtext('раз')),8,'0'))::bit(32)::int AS dec2;

select md5('привет, мир!') as md5_,
       (length(md5('привет, мир!')) = 32)::boolean as len32_,
       md5('привет, мир!')::uuid as uuid_;
