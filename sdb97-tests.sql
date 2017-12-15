CREATE OR REPLACE LANGUAGE plpython3u;

--SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public';
DROP TABLE IF EXISTS Foo CASCADE;
DROP TABLE IF EXISTS Bar CASCADE;
DROP TABLE IF EXISTS Baz CASCADE;
CREATE TABLE Baz(id INT PRIMARY KEY);
CREATE TABLE Bar(id INT PRIMARY KEY, baz_id INT NOT NULL REFERENCES Baz);
CREATE TABLE Foo(id INT PRIMARY KEY, bar_id INT NOT NULL REFERENCES Bar);
DELETE FROM Foo;
DELETE FROM Bar;
DELETE FROM Baz;
INSERT INTO Baz (id) (SELECT n FROM generate_series(1,30) AS G(n));
INSERT INTO Bar (id, baz_id) (SELECT n,(MOD(n,30)+1)m FROM generate_series(1,50) AS G(n)); 
INSERT INTO Foo (id, bar_id) (SELECT n,(MOD(n,50)+1)m FROM generate_series(1,100) AS G(n)); 
-- SELECT * FROM Foo JOIN Bar ON Foo.bar_id=Bar.id JOIN Baz ON Bar.baz_id=Baz.id;


DROP FUNCTION IF EXISTS test01;
CREATE OR REPLACE FUNCTION test01(q int = 0) RETURNS void
AS $$
<<outer_blk>>
DECLARE
	q int := 1;
BEGIN
	RAISE NOTICE 'Q1=%', q;
	q := 2;
	RAISE NOTICE 'Q2=%', q;
	DECLARE
		q int := 3;
	BEGIN
		RAISE NOTICE 'Q3=%', q;
		q := 4;
		RAISE NOTICE 'Q4=%', q;
		RAISE NOTICE 'Q5=%', outer_blk.q;
	END;
	RAISE NOTICE 'Q6=%', q;
	RAISE INFO 'Q7=%', test01.q;
END
$$ LANGUAGE plpgsql;
SELECT test01();


DROP FUNCTION IF EXISTS test02;
CREATE OR REPLACE FUNCTION test02(INT = 5) RETURNS SETOF Foo
AS $$
DECLARE
	li_mit ALIAS FOR $1;
	rec Foo%ROWTYPE;
	max_n CONSTANT INT := 20;
	n li_mit%TYPE NOT NULL DEFAULT li_mit;
	url VARCHAR = 'https://www.oracle.com';
BEGIN
	IF n > max_n THEN
		n := max_n;
	END IF;
	FOR rec IN (SELECT * FROM Foo ORDER BY id DESC LIMIT n) LOOP
		RETURN NEXT rec;
	END LOOP;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test02(4);
SELECT test02(2);


DROP FUNCTION IF EXISTS test03;
CREATE OR REPLACE FUNCTION test03(REAL, OUT REAL) AS $$
BEGIN
	$2 := $1 * 0.05;
END
$$ LANGUAGE plpgsql;
SELECT test03(50);
SELECT * FROM test03(25);


DROP FUNCTION IF EXISTS test04;
CREATE OR REPLACE FUNCTION test04(REAL, REAL, OUT REAL, OUT REAL) AS $$
DECLARE
	a ALIAS FOR $1;
	b ALIAS FOR $2;
	sum ALIAS FOR $3;
	prod ALIAS FOR $4;
BEGIN
	sum := a + b;
	prod := a * b;
END
$$ LANGUAGE plpgsql;

SELECT test04(2,3);
SELECT * FROM test04(2,3);


-- anonymous code block must return VOID (no selects)
DO LANGUAGE plpgsql $$ -- language cna be omitted
DECLARE
	s REAL;
	p REAL;
BEGIN
	SELECT INTO s, p FROM test04(2,3);
	RAISE NOTICE 'NULL: s=% p=%', s, p;
	SELECT * INTO s, p FROM test04(2,3);
	RAISE NOTICE 'O.K.: s=% p=%', s, p;
END $$; -- language can be omitted


-- example of python3 anonymous block 
DO LANGUAGE plpython3u $$
	i = 10050
	s = 'World'
	plpy.notice('Hello, %s!' % s)
	plpy.info('Count = %d' % i)
	plan = plpy.prepare('SELECT * FROM Foo WHERE id >= $1', ['INTEGER'])
	for r in plpy.execute(plan, ['10'], 3):
		plpy.info('Foo id = %s' % r['id'])
	ids = [r['id'] for r in plpy.cursor('SELECT * FROM Foo WHERE id >= 10 LIMIT 3')]
	plpy.info('Foo ids = %s' % ids)
$$;


DROP FUNCTION IF EXISTS test05;
CREATE OR REPLACE FUNCTION test05(num INT)
RETURNS TABLE(id INT, id2 REAL) AS $$
BEGIN
	RETURN QUERY
	SELECT F.id, (F.id::REAL / 2)::REAL
	FROM Foo F LIMIT num; 
END
$$ LANGUAGE plpgsql;
SELECT test05(2);
SELECT * FROM test05(5);


DROP FUNCTION IF EXISTS test06;
CREATE OR REPLACE FUNCTION test06(x Foo) RETURNS INTEGER AS $$
BEGIN
	RETURN -1 * (10000 + x.id * 100 + x.bar_id);
END
$$ LANGUAGE plpgsql;
SELECT test06(F.*) FROM Foo F LIMIT 5; 


DROP FUNCTION IF EXISTS test07;
CREATE OR REPLACE FUNCTION test07(x Foo) RETURNS Foo AS $$
DECLARE
	r Foo;
BEGIN
	r.id := -x.id;
	r.bar_id := -x.bar_id;
	RETURN r;
END
$$ LANGUAGE plpgsql;
SELECT test07(F.*) FROM Foo F LIMIT 1;  -- ????? 


DROP TABLE IF EXISTS test08;
CREATE TABLE test08 (x INT);
DROP FUNCTION IF EXISTS test08;
CREATE OR REPLACE
FUNCTION test08() RETURNS INTEGER AS $$
DECLARE
	n INT;
BEGIN 
	-- goal: invoke a function with side effects
	-- problem: SELECT without INTO will be rejected...
	-- solution: PERFORM
	PERFORM version();      -- invoke a function with side effects
	PERFORM * FROM test08;  -- SELECT replaced by PERFORM can return many rows
	PERFORM (SELECT * FROM test08 LIMIT 1);  -- (query) must return 1 row
	PERFORM (SELECT COUNT(*) FROM test08);   -- (query) must return 1 row
	-- SELECT with INTO is allowed
	SELECT COUNT(*) INTO n FROM test08;
	-- INSERT / UPDATE is allowed too
	INSERT INTO test08 VALUES (n);
	IF n > 5 THEN
		DELETE FROM test08;  -- DELETE is also allowed
	END IF;
	RETURN n;
END
$$ LANGUAGE plpgsql;
SELECT test08();
SELECT * FROM test08;


DROP FUNCTION IF EXISTS test09;
CREATE OR REPLACE
FUNCTION test09(t VARCHAR, a INT, b INT) RETURNS INT AS $$
DECLARE
	res INT;
BEGIN
	EXECUTE format('SELECT COUNT(id) FROM %I '
                   'WHERE id BETWEEN $1 AND $2', LOWER(t))
        INTO res USING a, b;
	RETURN res;
END
$$ LANGUAGE plpgsql;
SELECT test09('Foo', 5, 7);


DROP TABLE IF EXISTS test10;
CREATE TABLE test10(x INT);
DROP FUNCTION IF EXISTS test10;
CREATE OR REPLACE
FUNCTION test10(t VARCHAR, a INT, b INT) RETURNS INT AS $$
DECLARE
	res INT;
BEGIN
	EXECUTE format('INSERT INTO %I VALUES ($1),($2)', LOWER(t)) USING a,b;
	GET DIAGNOSTICS res = ROW_COUNT;
	RETURN res;
END
$$ LANGUAGE plpgsql;
SELECT test10('Test10', 2, 5);


DROP FUNCTION IF EXISTS test11;
CREATE OR REPLACE FUNCTION test11(a REAL, b REAL, OUT r REAL) AS $$
BEGIN
	r := -666;  
	r := a / b;
EXCEPTION
	WHEN Division_By_Zero THEN
		NULL;
END
$$ LANGUAGE plpgsql;
SELECT test11(1,2);
SELECT test11(3,0);


DROP FUNCTION IF EXISTS test12;
CREATE OR REPLACE
FUNCTION test12(n INT, c INT) RETURNS SETOF Foo AS $$
BEGIN
	FOR i IN 1..n LOOP
		RETURN NEXT (i, i*c);
	END LOOP;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test12(3,6);


DROP FUNCTION IF EXISTS test13;
CREATE OR REPLACE
FUNCTION test13(t VARCHAR, a INT, b INT) RETURNS SETOF Foo AS $$
BEGIN
	RETURN QUERY EXECUTE format('SELECT * FROM %I WHERE id BETWEEN $1 AND $2', LOWER(t)) USING a,b;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test13('Foo', 52, 55);


CREATE OR REPLACE FUNCTION test14(x INT, OUT r VARCHAR) AS $$
BEGIN
	CASE x
        WHEN 2,4,6,8 THEN r := 'even';
        WHEN 1,3,5,7 THEN r := 'odd';
        WHEN 0 THEN r := 'zero';
		ELSE r := NULL;
    END CASE;
END 
$$ LANGUAGE plpgsql;
SELECT test14(1);
SELECT test14(0);
SELECT test14(9);


CREATE OR REPLACE FUNCTION test15(x INT, OUT r VARCHAR) AS $$
BEGIN
	CASE
        WHEN x > 0 THEN r := 'positive';
        WHEN x < 0 THEN r := 'negative';
        WHEN x = 0 THEN r := 'zero';
        ELSE NULL;
    END CASE;
END 
$$ LANGUAGE plpgsql;
SELECT test15(1);
SELECT test15(-2);
SELECT test15(0);
SELECT test15(NULL);


CREATE OR REPLACE FUNCTION test16(x INT, OUT r VARCHAR) AS $$
BEGIN
	IF x > 0 THEN r := 'positive';
    ELSIF x < 0 THEN r := 'negative';
    ELSEIF x = 0 THEN r := 'zero';
    ELSE NULL;
    END IF;
END 
$$ LANGUAGE plpgsql;
SELECT test16(1);
SELECT test16(-2);
SELECT test16(0);
SELECT test16(NULL);


DROP FUNCTION IF EXISTS test17;
CREATE OR REPLACE FUNCTION test17(c REAL = 1) RETURNS SETOF REAL AS $$
DECLARE
	rec RECORD;
BEGIN
 	<<rec_loop>>
	FOR rec IN
		SELECT * FROM Foo
	LOOP
		CONTINUE WHEN MOD(rec.id, 2) = 0;
		EXIT rec_loop WHEN rec.id > 5;
		RETURN NEXT rec.id * c;
	END LOOP;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test17();
SELECT test17(1.5);


DROP FUNCTION IF EXISTS test18(INT, BOOL, INT);
DROP FUNCTION IF EXISTS test18(INT, BOOL);
DROP FUNCTION IF EXISTS test18(INT);
CREATE OR REPLACE
FUNCTION test18(n INT, rev BOOL = FALSE, step INT = 1) RETURNS SETOF INT AS $$
DECLARE
	rec RECORD;
BEGIN
 	IF rev THEN
 		FOR i IN REVERSE n-1..0 BY step LOOP
			RETURN NEXT i;
		END LOOP;
	ELSE
		FOR i IN 0..n-1 BY step LOOP
			RETURN NEXT i;
        END LOOP;
	END IF;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test18(7);
SELECT test18(6, TRUE);
SELECT * FROM test18(7, FALSE, 2);
SELECT test18(6, TRUE, 2);


DROP FUNCTION IF EXISTS test19;
CREATE OR REPLACE FUNCTION test19(c REAL = 1) RETURNS SETOF REAL AS $$
DECLARE
	id INT;
	id2 INT;
BEGIN
	FOR id, id2 IN SELECT * FROM Foo LIMIT 5 LOOP
		RETURN NEXT id * c;
	END LOOP;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test19(2);


DROP FUNCTION IF EXISTS test20;
CREATE OR REPLACE FUNCTION test20(a REAL[]) RETURNS REAL AS $$
DECLARE
	v REAL;
	s REAL := 0.0;
BEGIN
	FOREACH v IN ARRAY a LOOP
		s := s + v;
	END LOOP;
	RETURN s;
END
$$ LANGUAGE plpgsql;
SELECT test20(ARRAY[1,2,3]);


DROP FUNCTION IF EXISTS test21;
CREATE OR REPLACE
FUNCTION test21(i INT) RETURNS RECORD AS $$
DECLARE
	msg TEXT;
	col TEXT;
	con TEXT;
BEGIN
	INSERT INTO Baz VALUES (i);
	RETURN (NULL, NULL, NULL);
EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS
			msg = MESSAGE_TEXT,
			col = COLUMN_NAME,
			con = CONSTRAINT_NAME;
		RETURN (msg, col, con);
END
$$ LANGUAGE plpgsql;
SELECT test21(1);


DROP FUNCTION IF EXISTS test22;
CREATE OR REPLACE
FUNCTION test22(n INT) RETURNS SETOF Foo AS $$
DECLARE
	cur1 CURSOR FOR SELECT * FROM Foo WHERE id <= n;
	rid RECORD;
BEGIN
	OPEN cur1;
	FETCH cur1 INTO rid;
	WHILE FOUND LOOP
		RETURN NEXT rid;
		FETCH cur1 INTO rid;
	END LOOP;
	CLOSE cur1;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test22(3);


DROP FUNCTION IF EXISTS test23;
CREATE OR REPLACE
FUNCTION test23(n INT) RETURNS SETOF Foo AS $$
DECLARE
	cur1 CURSOR (maxid INT) IS SELECT * FROM Foo WHERE id <= maxid;
	rid Foo;
BEGIN
	OPEN cur1(maxid := n);
	LOOP
		FETCH cur1 INTO rid;
		EXIT WHEN NOT FOUND;
		RETURN NEXT rid;
	END LOOP;
	CLOSE cur1;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test23(5);


DROP FUNCTION IF EXISTS test24;
CREATE OR REPLACE
FUNCTION test24(n INT) RETURNS SETOF INT AS $$
DECLARE
	cur1 refcursor;
	id1 INT;
	id2 INT;
BEGIN
	ASSERT n > 0, 'argument must be positive';
	OPEN cur1 FOR SELECT * FROM Foo WHERE id <= n;
	LOOP
		FETCH cur1 INTO id1, id2;
		EXIT WHEN NOT FOUND;
		RETURN NEXT id2;
	END LOOP;
	CLOSE cur1;
END
$$ LANGUAGE plpgsql;
SELECT * FROM test24(4);
SELECT * FROM test24(-1);


DROP FUNCTION IF EXISTS test25;
CREATE OR REPLACE
FUNCTION test25(n INT) RETURNS SETOF Foo AS $$
DECLARE
BEGIN
END
$$ LANGUAGE plpgsql;
SELECT * FROM test25(24);


DROP FUNCTION IF EXISTS test26;
CREATE OR REPLACE FUNCTION test26(ary ANYARRAY,
                                  v ANYELEMENT = NULL)  -- TRICK HERE! its type will correlate with `ary`
                  RETURNS SETOF ANYNONARRAY AS $$
DECLARE
BEGIN
	FOREACH v IN ARRAY ary LOOP
		RETURN NEXT v;
	END LOOP;
END 
$$ LANGUAGE plpgsql;
SELECT * FROM test26(ARRAY[1,2,3]);
SELECT * FROM test26(ARRAY[1.5,2.5,3.5]);
SELECT * FROM test26(ARRAY['a','b','c']);




SELECT array_length(array[1,2,3,4,5], 1);
SELECT mod((random() * 65536)::int, 10) + 1;

DO LANGUAGE plpgsql $$
DECLARE
	a INT[] := ARRAY[0,1,2,3,4,5,6,7,8,9];
	i INT := 1; 
BEGIN
	RAISE NOTICE 'len(a) = %', ARRAY_LENGTH(a, 1);
	RAISE NOTICE 'a[i] = %', a[random() * 10 + 1];
END $$;


SELECT * from pg_collation where lower(collname) like '%ru%';
SELECT * from pg_database;