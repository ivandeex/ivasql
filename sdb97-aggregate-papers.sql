DROP TABLE IF EXISTS Conference CASCADE;
DROP TABLE IF EXISTS ConferenceEvent CASCADE;
DROP TABLE IF EXISTS Paper CASCADE;
DROP TYPE IF EXISTS Float2;

CREATE TABLE ConferenceEvent(
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  year INT NOT NULL,
  UNIQUE(name, year)
);

CREATE TABLE Paper(
  id SERIAL PRIMARY KEY,
  event_id INT NOT NULL REFERENCES ConferenceEvent,
  title TEXT
);

INSERT INTO ConferenceEvent(id, name, year) VALUES
  (15, 'SIGMOD', 2015), (16, 'SIGMOD', 2016), (17, 'SIGMOD', 2017),
  (25, 'KILLAL', 2015),                       (27, 'KILLAL', 2017);

INSERT INTO Paper(event_id) VALUES
  (15), (15), (15),
  (16), (16),
  (17),
  (25), (25),
  (27), (27), (27), (27);

-- SubmittedPapersPerEvent
SELECT name, year, COUNT(*) AS paper_count
FROM Paper P JOIN ConferenceEvent CE ON P.event_id = CE.id
GROUP BY name, YEAR
ORDER BY 1,2;

-- AverageSubmissionPerConference
WITH
  SubmittedPapersPerEvent AS (
    SELECT name, year, COUNT(*) AS paper_count
    FROM Paper P JOIN ConferenceEvent CE ON P.event_id = CE.id
    GROUP BY name, year)
SELECT name, AVG(paper_count) AS avg_count
FROM SubmittedPapersPerEvent
GROUP BY name;

-- relate submitted per event to average over years
WITH
  SubmittedPapersPerEvent AS (
    SELECT name, year, COUNT(*) AS paper_count
    FROM Paper P JOIN ConferenceEvent CE ON P.event_id = CE.id
    GROUP BY name, year),
  AverageSubmissionPerConference AS (
    SELECT name, AVG(paper_count) AS avg_count
    FROM SubmittedPapersPerEvent
    GROUP BY name)
SELECT E.name, year, paper_count / avg_count AS ratio
FROM SubmittedPapersPerEvent E
JOIN AverageSubmissionPerConference A ON E.name = A.name
ORDER BY 1,2;

-- use view
DROP VIEW IF EXISTS SubmittedPapersPerEvent;
CREATE OR REPLACE VIEW SubmittedPapersPerEvent AS
  SELECT name, year, COUNT(*) AS paper_count
  FROM Paper P JOIN ConferenceEvent CE ON P.event_id = CE.id
  GROUP BY name, year;

WITH
  AverageSubmissionPerConference AS (
    SELECT name, AVG(paper_count) AS avg_count
    FROM SubmittedPapersPerEvent
    GROUP BY name)
SELECT E.name, year, paper_count / avg_count AS ratio
FROM SubmittedPapersPerEvent E
JOIN AverageSubmissionPerConference A ON E.name = A.name
ORDER BY 1,2;

-- use window function
SELECT name, year, paper_count / AVG(paper_count) OVER (PARTITION BY name) AS ratio
FROM SubmittedPapersPerEvent ORDER BY 1,2;

SELECT name, year, SUM(paper_count) OVER (PARTITION BY name)
FROM SubmittedPapersPerEvent ORDER BY 1,2;

SELECT name, year, SUM(paper_count) OVER (PARTITION BY name ORDER BY year)
FROM SubmittedPapersPerEvent ORDER BY 1,2;

SELECT * FROM SubmittedPapersPerEvent;
SELECT name, SUM(paper_count) FROM SubmittedPapersPerEvent GROUP BY name;
SELECT name, SUM(paper_count) OVER (PARTITION BY name) FROM SubmittedPapersPerEvent;

SELECT name, year, paper_count AS count, 
       FIRST_VALUE(paper_count) OVER (
         PARTITION BY name ORDER BY year
         ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
       AS prev,
       FIRST_VALUE(paper_count) OVER (
         PARTITION BY name ORDER BY YEAR DESC
         ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
       AS next
FROM SubmittedPapersPerEvent ORDER BY 1,2;

SELECT name, year, paper_count AS count, 
       LAG(paper_count) OVER (PARTITION BY name ORDER BY year) AS prev,
       LEAD(paper_count) OVER (PARTITION BY name ORDER BY year) AS next
FROM SubmittedPapersPerEvent ORDER BY 1,2;

SELECT name, year, paper_count AS count,
       (paper_count::REAL / FIRST_VALUE(paper_count) OVER ByName2)::NUMERIC(3,2) AS growth,
       paper_count::REAL / MAX(paper_count) OVER () AS norm_by_max,
       AVG(paper_count) OVER (PARTITION BY year) avg_by_year,
       AVG(paper_count) OVER (PARTITION BY name) avg_by_name,
       paper_count = MIN(paper_count) OVER () AS is_min
FROM SubmittedPapersPerEvent
WINDOW ByName2 AS (PARTITION BY name ORDER BY YEAR
                   ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
ORDER BY 1,2;
