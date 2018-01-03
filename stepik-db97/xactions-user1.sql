----------------------------------------------------
-- TEST #01 (intro)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey(id, capacity, booked) VALUES (1, 100, 15);
COMMIT;

BEGIN;
UPDATE Journey SET booked = booked + 2 WHERE id=1;
COMMIT;
SELECT * FROM Journey;

----------------------------------------------------
-- TEST #02 (read uncommitted)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey(id, capacity, booked) VALUES (1, 100, 15);
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- (Note: READ UNCOMMITTED is not really supported by postgres)
SELECT booked FROM Journey WHERE id=1;
UPDATE Journey SET booked = 15 + 2 WHERE id=1;
ROLLBACK;
SELECT * FROM Journey;

----------------------------------------------------
-- TEST #03 (read committed, update relative)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 7);
COMMIT;
SELECT * FROM Journey;

BEGIN; -- read committed;
SELECT * FROM Journey;
UPDATE Journey SET booked=booked+2 WHERE id=1;
-- ...
COMMIT;


BEGIN; -- read committed
SELECT * FROM Journey;
UPDATE Journey SET booked=booked+2 WHERE id=1;
-- user2: update...
ROLLBACK;


----------------------------------------------------
-- TEST #04 (read committed, update absolute)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 7);
COMMIT;
SELECT * FROM Journey;

BEGIN; -- read committed
SELECT booked FROM Journey WHERE id=1;
-- got 7 in _booked1...
-- _booked1 += 2
UPDATE Journey SET booked=9 WHERE id=1;
COMMIT;
SELECT * FROM Journey;

----------------------------------------------------
-- TEST #05 (read committed, select for update)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 7);
COMMIT;
SELECT * FROM Journey;

BEGIN; -- read committed
SELECT booked FROM Journey WHERE id=1 FOR UPDATE; -- INTO _booked1...
-- got 7 in _booked1...
-- _booked1 += 2
UPDATE Journey SET booked=9 WHERE id=1;
COMMIT;
SELECT * FROM Journey;
SELECT * FROM Journey;

----------------------------------------------------
-- TEST #06 (read committed, compare-and-swap)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 10);
COMMIT;
SELECT * FROM Journey;

BEGIN;
SELECT booked FROM Journey WHERE id=1; -- INTO _booked1
-- _old_booked1 = 10;  _new_booked1 = 11;
UPDATE Journey SET booked=11 WHERE id=1 AND booked=10; -- CAS
-- updated 1 rows
COMMIT;
--
SELECT * FROM Journey; -- 11

----------------------------------------------------
-- TEST # 07 (ugadayka)
ROLLBACK;
DROP TABLE IF EXISTS T CASCADE;
CREATE TABLE T(id INT, value INT);
INSERT INTO T(id, value) VALUES (1, 10), (2, 9);
COMMIT;
SELECT * FROM T;

BEGIN;
--
UPDATE T SET value=value+1;
--
COMMIT;
--
SELECT * FROM T;

----------------------------------------------------
-- TEST #08 (read committed follows external updates)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 1e6, 100500);
COMMIT;

CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
DECLARE
    count_for_if_   INTEGER;
    count_for_mail_ INTEGER;
BEGIN
    SELECT sum(booked) INTO count_for_if_ FROM Journey;
    IF count_for_if_ = 100500 THEN
        PERFORM pg_sleep(10); -- wait 10 seconds
        SELECT sum(booked) INTO count_for_mail_ FROM Journey;
        RETURN format('Welcome, dear passenger # %s !', count_for_mail_);
    END IF;
END
$$ LANGUAGE plpgsql;

BEGIN; -- ISOLATION LEVEL READ COMMITTED;
SELECT test();
-- .... Welcome #10499 :(
COMMIT;

----------------------------------------------------
-- TEST # 09 (repeatable read hides external updates)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 1e6, 100500);
COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ; -- <--- the trick!
SELECT test();
-- .... Welcome #10500 :)
COMMIT;

----------------------------------------------------
-- TEST # 10 (read committed -- phantom reading)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 100, 22);
COMMIT;

BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT sum(booked) OVER (), * FROM Journey;
-- user2 inserting, not yet committed
SELECT sum(booked) OVER (), * FROM Journey;
-- user2 inserted & committed
SELECT sum(booked) OVER (), * FROM Journey;
COMMIT;

----------------------------------------------------
-- TEST # 11 (repeatable read - no phantom reading in postgres)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 100, 22);
COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT sum(booked) OVER (), * FROM Journey;
-- user2 inserting, not yet committed
SELECT sum(booked) OVER (), * FROM Journey;
-- ...
-- user2 inserted & committed
SELECT sum(booked) OVER (), * FROM Journey;
COMMIT;
-- at this point we see the row inserted & committed by user2
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT sum(booked) OVER (), * FROM Journey;
COMMIT;

----------------------------------------------------
-- TEST # 12 (repeatable read prevents cross-updates)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 100, 22);
COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM Journey;
-- user2 updates journey #1...
-- ...and commits
SELECT * FROM Journey;
-- now it's our time to update
UPDATE Journey SET booked = booked + 2 WHERE id=1;
-- ERROR: could not serialize access due to concurrent update
ROLLBACK;

BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM Journey; -- now user1 can see user2's changes
UPDATE Journey SET booked = booked + 2 WHERE id=1;
COMMIT;
SELECT * FROM Journey; -- success!

----------------------------------------------------
-- TEST # 13 (transactions with dependency cycle)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
TRUNCATE TABLE JourneyBooking CASCADE;
TRUNCATE TABLE UserAct CASCADE;
TRUNCATE TABLE Booking CASCADE;
TRUNCATE TABLE BookingPos CASCADE;
INSERT INTO UserAct(id,credit,miles) VALUES (1,150,0);
INSERT INTO Booking(id,refcode,payer) VALUES (1,'ref1',1);
COMMIT;

-- TRANSACTION T1 insert booking position
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT credit -- INTO _credit
FROM UserAct WHERE id=1;
-- IF _credit > 100 THEN
    INSERT INTO BookingPos(booking_id,name,payed)
           VALUES (1, 'Коля Герасимов', 100);
-- END IF;


-- ...delayed by scheduler...






COMMIT;

SELECT * FROM BookingPos;

----------------------------------------------------
-- TEST # 14 (serializable level fixes dependency cycle)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
TRUNCATE TABLE JourneyBooking CASCADE;
TRUNCATE TABLE UserAct CASCADE;
TRUNCATE TABLE Booking CASCADE;
TRUNCATE TABLE BookingPos CASCADE;
INSERT INTO UserAct(id,credit,miles) VALUES (1,150,0);
INSERT INTO Booking(id,refcode,payer) VALUES (1,'ref1',1);
COMMIT;

-- TRANSACTION T1 insert booking position
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT credit -- INTO _credit
       FROM UserAct WHERE id=1;
-- IF _credit > 100 THEN
    INSERT INTO BookingPos(booking_id,name,payed)
           VALUES (1, 'Коля Герасимов', 100);
-- END IF;


-- ...delayed by scheduler...






COMMIT; -- ERROR: could not serialize access due to
        -- read/write dependencies among transactions
SELECT * FROM BookingPos;

----------------------------------------------------
-- TEST # 15 (read-only transactions)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
TRUNCATE TABLE JourneyBooking CASCADE;
COMMIT;

BEGIN READ ONLY ISOLATION LEVEL REPEATABLE READ;
COMMIT;

BEGIN ISOLATION LEVEL SERIALIZABLE READ ONLY;
COMMIT;

BEGIN READ ONLY;
UPDATE UserAct SET miles = 3 WHERE id=5; -- would change nothing
-- ERROR: cannot execute UPDATE in s read-only transaction
ROLLBACK;

-- END --
