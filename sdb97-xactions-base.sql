DROP TABLE IF EXISTS Journey CASCADE;
DROP TABLE IF EXISTS UserAct CASCADE;
DROP TABLE IF EXISTS Booking CASCADE;
DROP TABLE IF EXISTS BookingPos CASCADE;
DROP TABLE IF EXISTS JourneyBooking CASCADE;

-- данные о рейсе
CREATE TABLE Journey (
	id SERIAL PRIMARY KEY,
	date DATE,
	capacity INT,
	booked INT,
	CHECK(capacity > 0),
	CHECK(capacity >= booked)
);

-- пользовательская запись и остаток денег на счету
CREATE TABLE UserAct(
	id SERIAL PRIMARY KEY,
	credit INT,
	miles FLOAT,
	CHECK(credit >= 0)
);

-- резервирование и кто платит
CREATE TABLE Booking (
	id SERIAL PRIMARY KEY,
	refcode TEXT,
	payer INT REFERENCES UserAct
);

-- позиция в билете
CREATE TABLE BookingPos (
	booking_id INT REFERENCES Booking,
	name TEXT,
	payed INT,
	UNIQUE(booking_id, name)
);

-- связь между резервированием и рейсами
CREATE TABLE JourneyBooking (
	journey_id INT REFERENCES Journey,
	booking_id INT REFERENCES Booking
);

CREATE OR REPLACE FUNCTION
	CreateBooking(refcode_ TEXT, payer_uid_ INT) RETURNS INT
AS $$
DECLARE
	booking_id_ INT;
BEGIN
	INSERT INTO Booking(refcode, payer) VALUES (refcode_, payer_uid_)
		RETURNING id INTO booking_id_;
	RETURN booking_id_;
END
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS AddBookingPos;
CREATE OR REPLACE FUNCTION
	AddBookingPos(_booking_id INT, _name TEXT, _payed INT) RETURNS void AS $$
BEGIN
	INSERT INTO BookingPos (booking_id, name, payed)
		VALUES (_booking_id, _name, _payed);
END 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
	CheckCapacityAndDoBook(_journey_id INT, _booking_id INT) RETURNS void
AS $$
BEGIN
	INSERT INTO JourneyBooking VALUES (_journey_id, _booking_id);
END
$$ LANGUAGE plpgsql;

ROLLBACK;
TRUNCATE TABLE UserAct CASCADE;
TRUNCATE TABLE Booking CASCADE;
TRUNCATE TABLE Journey CASCADE;
SELECT setval('Booking_Id_Seq', 1); 

INSERT INTO UserAct(id, credit) VALUES (101, 500);
INSERT INTO Journey(id, capacity, booked) VALUES (201, 100, 0);
COMMIT;

ROLLBACK;
BEGIN;
SELECT CreateBooking('F23ML9', 101);
SELECT AddBookingPos(2, 'Дедка', 100);
SELECT AddBookingPos(2, 'Внучка', 50);
SELECT AddBookingPos(2, 'Жучка', 10);
SELECT CheckCapacityAndDoBook(201, 2);
COMMIT;

SELECT * FROM Journey;
SELECT * FROM Booking;
SELECT * FROM BookingPos;
