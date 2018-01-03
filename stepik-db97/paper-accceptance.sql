DROP TABLE IF EXISTS Conference CASCADE;
DROP TABLE IF EXISTS ConferenceEvent CASCADE;
DROP TABLE IF EXISTS Paper CASCADE;
DROP VIEW IF EXISTS HighPaperAcceptance;

-- Серия ежегодных конференций
CREATE TABLE Conference (
  id   INT PRIMARY KEY,
  name TEXT
);

-- "Событие" -- конференция в конкретном году
CREATE TABLE ConferenceEvent (
  id               INT PRIMARY KEY,
  conference_id    INT REFERENCES Conference,
  year             INT,
  total_papers     INT,
  accepted_papers  INT,
  acceptance_ratio NUMERIC(3, 2),
  UNIQUE (conference_id, year)
);

CREATE OR REPLACE VIEW HighPaperAcceptance AS
SELECT C.name, CE.year, CE.total_papers, CE.acceptance_ratio
FROM ConferenceEvent CE 
JOIN Conference C ON C.id = CE.conference_id
WHERE CE.total_papers > 5 AND CE.acceptance_ratio > 0.75;
SELECT * FROM HighPaperAcceptance;

DROP VIEW HighPaperAcceptance;
ALTER TABLE ConferenceEvent DROP COLUMN total_papers;
ALTER TABLE ConferenceEvent DROP COLUMN accepted_papers;
ALTER TABLE ConferenceEvent DROP COLUMN acceptance_ratio;
CREATE TABLE Paper(
  id INT PRIMARY KEY,
  event_id INT REFERENCES ConferenceEvent,
  title TEXT,
  accepted BOOLEAN
);

DROP VIEW IF EXISTS HighPaperAcceptance;
CREATE OR REPLACE VIEW HighPaperAcceptance AS
SELECT C.name, CE.year, PC.total_papers::INT, PC.acceptance_ratio::NUMERIC(3,2)
FROM ConferenceEvent CE
JOIN Conference C ON C.id = CE.conference_id
JOIN (SELECT event_id, COUNT(*) AS total_papers, AVG(accepted::INT) AS acceptance_ratio 
      FROM Paper GROUP BY event_id) AS PC ON CE.id = PC.event_id
WHERE PC.total_papers > 5 AND PC.acceptance_ratio > 0.75;
SELECT * FROM HighPaperAcceptance;

DROP TABLE IF EXISTS TestPaper;
CREATE TABLE TestPaper(event INT, accepted BOOLEAN);
DELETE FROM TestPaper;
INSERT INTO TestPaper VALUES (1,false),(1,false),(1,true),(2,false),(3,true);
SELECT SUM(accepted::INT) AS accepted, SUM(1 - accepted::INT) not_accepted, event FROM TestPaper GROUP BY event;

SELECT TRUE::INT::REAL;
SELECT FALSE::INT::REAL;