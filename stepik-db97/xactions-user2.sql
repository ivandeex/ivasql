----------------------------------------------------
-- TEST #01 (intro)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey(id, capacity, booked) VALUES (1, 100, 15);
COMMIT;

BEGIN;
UPDATE Journey SET booked = booked+3 WHERE id=1;
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
-- ouch, 17 means "all booked"
ROLLBACK;
SELECT * FROM Journey;

----------------------------------------------------
-- TEST #03 (read committed, update relative)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 7);
COMMIT;
SELECT * FROM Journey;

BEGIN; -- read committed
SELECT * FROM Journey;
-- user1: update...
SELECT * FROM Journey;
-- user1: commit...
SELECT * FROM Journey;

BEGIN; -- read committed
SELECT * FROM Journey;
-- user1: update
UPDATE Journey SET booked=booked+1; -- pending commit from user1...
-- got rollback, unblock and update
COMMIT;

----------------------------------------------------
-- TEST #04 (read committed, update absolute)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 7);
COMMIT;
SELECT * FROM Journey;

BEGIN; -- read committed
SELECT booked FROM Journey WHERE id=1;
-- got 7 in _booked2...
-- _booked2 += 3
UPDATE Journey SET booked=10 WHERE id=1; -- pending another update...
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
--
SELECT booked FROM Journey WHERE id=1 FOR UPDATE;
-- got 9 in_booked2...
-- _booked2 += 3
UPDATE Journey SET booked=12 WHERE id=1;
COMMIT;
SELECT * FROM Journey;

----------------------------------------------------
-- TEST #06 (read committed, compare-and-swap)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 12, 10);
COMMIT;
SELECT * FROM Journey;

--
BEGIN;
SELECT booked FROM Journey WHERE id=1; -- INTO _booked2
-- _old_booked = 10;  _new_booked = 12;
UPDATE Journey SET booked=12 WHERE id=1 AND booked=10; -- CAS
-- update 0 rows
COMMIT;
SELECT * FROM Journey; -- 11

----------------------------------------------------
-- TEST # 07 (ugadayka)
ROLLBACK;
DROP TABLE IF EXISTS T CASCADE;
CREATE TABLE T(id INT, value INT);
INSERT INTO T(id, value) VALUES (1, 10), (2, 9);
COMMIT;
SELECT * FROM T;

--
BEGIN;
--
DELETE FROM t WHERE value = 10;
--
COMMIT;
SELECT * FROM T;

----------------------------------------------------
-- TEST # 08 (read committed follows external updates)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 1e6, 100500);
COMMIT;

-- ...











-- ...

BEGIN; -- ISOLATION LEVEL READ COMMITTED;
-- ...
UPDATE Journey SET booked = booked - 1 WHERE id=1;
COMMIT;

----------------------------------------------------
-- TEST # 09 (repeatable read hides external updates)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 1e6, 100500);
COMMIT;

BEGIN; -- ISOLATION LEVEL READ COMMITTED;
-- ...
UPDATE Journey SET booked = booked - 1 WHERE id=1;
COMMIT;

----------------------------------------------------
-- TEST # 10 (read committed -- phantom reading)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 100, 22);
COMMIT;

BEGIN;
-- user1 selecting...
INSERT INTO Journey VALUES (2, '2084-05-19', 200, 33);
-- user1 selecting...
COMMIT;
-- user1 selects our committed row


----------------------------------------------------
-- TEST # 11 (repeatable read - no phantom reading in postgres)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 100, 22);
COMMIT;

BEGIN;
-- user1 selecting...
INSERT INTO Journey VALUES (2, '2084-05-19', 200, 33);
-- user1 selecting...
SELECT sum(booked) OVER (), * FROM Journey;
COMMIT;
-- user1 selecting - our inserted row is still hidden

-- at this point user1 start new transaction
-- and starts to see our changes



----------------------------------------------------
-- TEST # 12 (repeatable read prevents cross-updates)
ROLLBACK;
TRUNCATE TABLE Journey CASCADE;
INSERT INTO Journey VALUES (1, '2084-05-09', 100, 22);
COMMIT;

BEGIN;
SELECT * FROM Journey;
UPDATE Journey SET booked = booked + 5 WHERE id=1;
COMMIT;
SELECT * FROM Journey;
-- now user1 tries to update...
-- ...and fails with error:
--    "could not serialize access due to concurrent update"


-- after rolling back and starting a new transactions,
-- user1 successfully updates data




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

-- TRANSACTION T2 updates credit
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM UserAct;

UPDATE UserAct SET credit = credit - 100 WHERE id=1;
COMMIT;

-- TRANSACTION T3 updates bonus miles
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM BookingPos; -- still empty!
UPDATE UserAct
SET miles = credit*0.01 + 0.1 * (
    SELECT coalesce(sum(payed),0) FROM BookingPos BP
    JOIN Booking B ON BP.booking_id = B.id
    WHERE B.payer=1)
WHERE id=1;
COMMIT;


SELECT * FROM UserAct;

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

-- TRANSACTION T2 updates credit
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM UserAct;

UPDATE UserAct SET credit = credit - 100 WHERE id=1;
COMMIT;

-- TRANSACTION T3 updates bonus miles
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM BookingPos; -- still empty!
UPDATE UserAct
SET miles = credit*0.01 + 0.1 * (
    SELECT coalesce(sum(payed),0) FROM BookingPos BP
    JOIN Booking B ON BP.booking_id = B.id
    WHERE B.payer=1)
WHERE id=1;
COMMIT;


SELECT * FROM UserAct;

----------------------------------------------------
-- TEST # 15 (read-only transactions)

-- see left side...














-- END --
