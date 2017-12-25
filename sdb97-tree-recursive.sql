
/*********************************************
 * Recursive CTE (common table expression)
 */

-- a constant
CREATE OR REPLACE FUNCTION MAX_FIB() RETURNS int
AS $$ return 400 $$ language plpython3u;

DROP DOMAIN IF EXISTS longint;
CREATE DOMAIN longint AS numeric(100);
WITH RECURSIVE Fibonacci AS (
	SELECT 1 AS ord, 1::longint AS val, 1::longint AS nextval
	UNION ALL
	SELECT ord+1, nextval, (val+nextval)::longint
	FROM Fibonacci WHERE ord < MAX_FIB()
) SELECT ord, val FROM Fibonacci;


/**********************************
 * Adjacency List
 */

DROP TABLE IF EXISTS Animal;
CREATE TABLE Animal (
	name TEXT PRIMARY KEY,
	parent TEXT REFERENCES Animal
);
DELETE FROM Animal;
INSERT INTO Animal (name, parent) VALUES
  ('all',NULL),
  ('fish','all'), ('bird','all'), ('beast','all'),
  ('salmon','fish'), ('whale','fish'), ('shark','fish'),
  ('sparrow','bird'), ('crow','bird'), ('pigeon','bird'),
  ('home','beast'), ('ape','beast'),
  ('cat','home'), ('dog','home'), ('cow','home'), ('sheep','home'),
  ('human','ape'), ('chimp','ape'), ('monkey','ape'),
  ('john','human'), ('mary','human'), ('zach','human');
  
WITH RECURSIVE AnimalHier AS (
	SELECT 0 AS level, name, parent FROM Animal WHERE parent IS NULL
	UNION
	SELECT Prev.level+1, Cur.name, Cur.parent
	FROM Animal Cur JOIN AnimalHier Prev ON Cur.parent = Prev.name
) SELECT * FROM AnimalHier;


/******************************************
 * Outline Numbers (Materialized Paths)
 */

DROP FUNCTION IF EXISTS is_prefix;
CREATE OR REPLACE FUNCTION
is_prefix(prefix int[], array_ int[]) RETURNS bool
AS $$ BEGIN
	RETURN prefix <= array_ AND prefix = array_[1:array_length(prefix,1)];
END $$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS Places;
CREATE TABLE Places(name TEXT PRIMARY KEY, path_ INT[]);

DELETE FROM Places;
INSERT INTO Places (name, path_) VALUES
  ('sun', '{1}'), ('alpha centauri', '{2}'), ('orion', '{3}'),
  ('nibiru', '{2,1}'), ('mercury', '{1,1}'), ('venus', '{1,2}'),
  ('earth', '{1,3}'), ('mars', '{1,4}'), ('jupiter', '{1,5}'),
  ('phobos', '{1,4,1}'), ('red spot', '{1,5,1}'),
  ('europe', '{1,3,1}'), ('london', '{1,3,1,1}'), ('paris', '{1,3,1,2}'),
  ('asia', '{1,3,2}'), ('beijing', '{1,3,2,1}'), ('singapore', '{1,3,2,2}');


WITH RECURSIVE PlacesHier AS (
	SELECT 0 AS level_, name, NULL AS parent, path_
	FROM Places WHERE array_length(path_,1) = 1
  UNION ALL
	SELECT P.level_ + 1 AS level_, C.name, P.name AS parent, C.path_
	FROM Places C JOIN PlacesHier P ON is_prefix(P.path_, C.path_)
	WHERE array_length(C.path_,1) = array_length(P.path_,1) + 1
) SELECT * FROM PlacesHier;


-- the next one is more common but less optimal
WITH RECURSIVE PlacesHier AS (
	SELECT 0 AS level_, name, NULL AS parent, path_
	FROM Places WHERE array_length(path_,1) = 1
  UNION ALL
	SELECT P.level_ + 1 AS level_, C.name, P.name AS parent, C.path_
	FROM Places C JOIN PlacesHier P ON is_prefix(P.path_, C.path_)
	WHERE array_length(C.path_,1) = (SELECT min(array_length(path_,1)) FROM Places
	                                 WHERE is_prefix(P.path_,path_) AND path_ > P.path_)
) SELECT * FROM PlacesHier;

/******************************
 * modified preorder
 */ 
DROP TABLE IF EXISTS Places CASCADE;
CREATE TABLE Places(
	name TEXT PRIMARY KEY,
	parent TEXT REFERENCES Places,
	nleft INT,
	nright INT
);

DELETE FROM Places;
INSERT INTO Places (name, parent) VALUES
  ('sun', NULL), ('orion', NULL), ('nibiru', 'orion'),
  ('mercury', 'sun'), ('venus', 'sun'), ('earth', 'sun'), ('mars', 'sun'), ('jupiter', 'sun'),
  ('phobos', 'mars'), ('red spot', 'jupiter'),
  ('europe', 'earth'), ('london', 'europe'), ('paris', 'europe'),
  ('asia', 'earth'), ('beijing', 'asia'), ('singapore', 'asia');

DROP FUNCTION IF EXISTS rebuild_mptt;
CREATE OR REPLACE FUNCTION rebuild_mptt(parent_ TEXT = NULL, nleft_ INT = 1) RETURNS INT AS $$
DECLARE
	nright_ INT;
	name_ TEXT;
BEGIN
	IF parent_ IS NULL THEN
		nright_ := nleft_;
		FOR parent_ IN
			SELECT name FROM Places WHERE parent IS NULL
		LOOP
			nright_ := rebuild_mptt(parent_, nright_);
		END LOOP;
	ELSE
		nright_ := nleft_ + 1;
		FOR name_ IN
			SELECT name FROM Places WHERE parent = parent_ ORDER BY name
		LOOP
			nright_ := rebuild_mptt(name_, nright_);
		END LOOP;
		UPDATE Places SET nleft = nleft_, nright = nright_ WHERE name = parent_;
	END IF;
	RETURN nright_ + 1;
END 
$$ LANGUAGE plpgsql;

SELECT rebuild_mptt();
SELECT P.*,
       (P.nright-P.nleft-1)/2 AS nchildren,
       array_agg(C.name ORDER BY C.nleft) AS children
FROM Places P
LEFT JOIN Places C ON C.nleft>P.nleft AND C.nright<P.nright
GROUP BY P.name,P.parent,P.nleft,P.nright
ORDER BY P.nleft;

/******************************
 * ltree
 */

CREATE EXTENSION IF NOT EXISTS ltree;

DROP TABLE IF EXISTS Places CASCADE;
CREATE TABLE Places(
	name TEXT PRIMARY KEY,
	parent TEXT REFERENCES Places,
	tpath ltree
);

DELETE FROM Places;
INSERT INTO Places (name, parent) VALUES
  ('sun', NULL), ('orion', NULL), ('nibiru', 'orion'),
  ('mercury', 'sun'), ('venus', 'sun'), ('earth', 'sun'), ('mars', 'sun'), ('jupiter', 'sun'),
  ('phobos', 'mars'), ('red_spot', 'jupiter'),
  ('europe', 'earth'), ('london', 'europe'), ('paris', 'europe'),
  ('asia', 'earth'), ('beijing', 'asia'), ('singapore', 'asia');

DROP FUNCTION IF EXISTS rebuild_tree;
CREATE OR REPLACE FUNCTION rebuild_tree(parent_ TEXT = NULL) RETURNS void AS $$
DECLARE
	name_ text;
	tpath_ ltree;
BEGIN
	IF parent_ IS NULL THEN
		UPDATE Places SET tpath = NULL;
		FOR parent_ IN
			SELECT name FROM Places WHERE parent IS NULL
		LOOP
			UPDATE Places
				SET tpath = parent_::ltree
				WHERE name = parent_;
			PERFORM rebuild_tree(parent_);
		END LOOP;
	ELSE
		SELECT tpath INTO tpath_ FROM Places WHERE name = parent_; 
		FOR name_ IN
			SELECT name FROM Places WHERE parent = parent_ ORDER BY name
		LOOP
			UPDATE Places SET tpath = tpath_ || name_ WHERE name = name_;
			PERFORM rebuild_tree(name_);
		END LOOP;
	END IF;
END
$$ LANGUAGE plpgsql;

SELECT rebuild_tree();
SELECT * FROM Places;
SELECT * FROM Places WHERE tpath ~ '*.asia|europe.*';
SELECT * FROM Places WHERE tpath @> 'sun.earth.asia';
SELECT * FROM Places WHERE tpath <@ 'sun.earth.asia';
SELECT * FROM Places WHERE tpath ~ '*.earth.*{1}';
SELECT * FROM Places WHERE tpath ~ '*.earth.*{2}';
SELECT * FROM Places WHERE tpath ~ 'sun.*{2}';
SELECT * FROM Places WHERE tpath ~ 'sun.*{1}';
SELECT * FROM Places WHERE tpath ~ 'sun.*{1,2}';
SELECT * FROM Places WHERE tpath ~ 'sun.*{2}' ORDER BY tpath DESC;
SELECT *, subpath(tpath,2,1) FROM Places WHERE tpath ~ 'sun.*{2}' ORDER BY subpath(tpath,2,1) ASC;
