----------------------------------------------------
-- HOMEWORK #1

ROLLBACK;
DROP TABLE IF EXISTS T CASCADE;
DROP TABLE IF EXISTS R CASCADE;
CREATE TABLE T(id int, value int);
CREATE TABLE R(id int, value int);
INSERT INTO T VALUES (1,10), (2,20);
INSERT INTO R VALUES (1,100), (2,200);
COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;          -- T2
BEGIN ISOLATION LEVEL READ COMMITTED;           -- T1
SELECT SUM(value) INTO _t2_sum FROM R;          -- T2 _t2_sum := 300
BEGIN ISOLATION LEVEL READ COMMITTED;           -- T3
SELECT value INTO _t1_value FROM T WHERE id=1;  -- T1 _t1_value := 10
SELECT MAX(value) INTO _t3_max FROM T;          -- T3 _t3_max := 20
UPDATE T SET value = _t1_value + 50 WHERE id=1; -- T1 T(1) := 10+50
COMMIT;                                         -- T1
UPDATE T SET value = _t2_sum WHERE id=1;        -- T2 T(1) :=  300 (ERROR)
COMMIT;                                         -- T2 ROLLBACK
UPDATE R SET value = _t3_max +
       (SELECT MAX(value) FROM T) WHERE id=2;   -- T3 R(2) := 20+60
COMMIT;                                         -- T3 OK, R(2) == 80

----------------------------------------------------
-- HOMEWORK #2
ROLLBACK;
DROP TABLE IF EXISTS T;
CREATE TABLE T(id int, group_id int, value int);
INSERT INTO T VALUES (1,1,500),(2,2,500),(3,1,500),(4,2,500);
COMMIT;

-- T (before)               T (after)
-- id  group_id  value      id  group_id  value
-- 1   1         500        1   1         300
-- 2   2         500        2   2         1000
-- 3   1         500        3   1         600
-- 4   2         500        4   2         500

BEGIN ISOLATION LEVEL REPEATABLE READ;         -- T3 BEGIN
BEGIN ISOLATION LEVEL READ COMMITTED;          -- T2 BEGIN
BEGIN ISOLATION LEVEL REPEATABLE READ;         -- T1 BEGIN
SELECT * FROM T WHERE group_id=1;              -- T1
UPDATE T SET value=value+100 WHERE group_id=1; -- T1
UPDATE T SET value=value*2 WHERE id=2;         -- T2
COMMIT;                                        -- T1 END
UPDATE T SET value=value/2 WHERE id=1;         -- T2
UPDATE T SET value=value-50 WHERE group_id=2;  -- T3
COMMIT;                                        -- T2 END
COMMIT;                                        -- T3 END

----------------------------------------------------
-- HOMEWORK #3
--
-- see: https://stepik.org/lesson/50202/step/4

-- Alice RC
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT value FROM T WHERE id = 2 FOR UPDATE; -- 0(2)
SELECT value FROM T WHERE id = 3 FOR UPDATE; -- 2(2)
SELECT value FROM T WHERE id = 4 FOR UPDATE; -- 4(2)
SELECT value FROM T WHERE id = 1 FOR UPDATE; -- 6(2) / 13(2) (pends on H's UPDATE)
UPDATE T SET value = value + 10 WHERE id BETWEEN 1 AND 4; -- 8(10) / 15(10)
COMMIT; -- 18 / 25
-- M_rc = 18(1-p)+25p

-- Alice RR (1st attempt)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT value FROM T WHERE id = 2; -- 0(1)
SELECT value FROM T WHERE id = 3; -- 1(1)
SELECT value FROM T WHERE id = 4; -- 2(1)
SELECT value FROM T WHERE id = 1; -- 3(1)
UPDATE T SET value = value + 10 WHERE id BETWEEN 1 AND 4; -- 4(10) / 4(...)
COMMIT; -- 14(OK) / 13(ROLLBACK)
-- (2nd attempt, only after ROLLBACK)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT value FROM T WHERE id = 2; -- 13(1)
SELECT value FROM T WHERE id = 3; -- 14(1)
SELECT value FROM T WHERE id = 4; -- 15(1)
SELECT value FROM T WHERE id = 1; -- 16(1)
UPDATE T SET value = value + 10 WHERE id BETWEEN 1 AND 4; -- 17(10)
COMMIT; -- x / 27 (only after ROLLBACK)
-- M_rr = 14(1-p)+27p

-- Alice II is better than Alice I:
-- M_rr < M_rc
-- 14(1-p)+27p < 18(1-p)+25p
-- p in [0,2/3)  <-- answer

-- Hatter
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT value FROM T WHERE id = 1 FOR UPDATE;     -- 0(2)
SELECT id /*inc INTO _inc*/ FROM R WHERE id = 1; -- 2(1)
UPDATE T SET value = value + 1/*_inc*/ WHERE id=1; -- 3(10)
COMMIT; -- 13(2+1+10=13) <-- Alice-RC wakes up / Alice-RR rolls back


-- END --
