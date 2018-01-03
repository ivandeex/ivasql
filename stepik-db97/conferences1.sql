DROP TABLE IF EXISTS Conference;
DROP TABLE IF EXISTS Location;
DROP TABLE IF EXISTS Paper;

CREATE TABLE Conference (
  id INTEGER NOT NULL,
  value TEXT
);
INSERT INTO Conference VALUES(1,'c1');
INSERT INTO Conference VALUES(2,'c2');
INSERT INTO Conference VALUES(3,'c3');
CREATE TABLE Paper (
  id INTEGER NOT NULL,
  title TEXT,
  conference TEXT,
  location TEXT
);
INSERT INTO Paper VALUES(1,'p1','c1','loca');
INSERT INTO Paper VALUES(2,'p2','c2','locb');
INSERT INTO Paper VALUES(3,'p3','c3','locc');
INSERT INTO Paper VALUES(4,'p4','c1','loca');
INSERT INTO Paper VALUES(5,'p5','c2','locb');
INSERT INTO Paper VALUES(6,'p6','c3','locz');
INSERT INTO Paper VALUES(7,'p7','c99','loc99');
CREATE TABLE Location (
  id INTEGER NOT NULL ,
  value TEXT
);
INSERT INTO Location VALUES(1,'l1');
INSERT INTO Location VALUES(2,'l2');
INSERT INTO Location VALUES(3,'l3');

SELECT conference FROM Paper WHERE conference NOT IN (SELECT value FROM Conference)
UNION
SELECT conference FROM Paper GROUP BY conference HAVING COUNT(DISTINCT location) > 1;