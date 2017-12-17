DROP VIEW IF EXISTS PaperCounts;
DROP VIEW IF EXISTS KeywordCounts;
DROP TABLE IF EXISTS PaperConference CASCADE;
DROP TABLE IF EXISTS PaperKeyword CASCADE;
DROP TABLE IF EXISTS Conference CASCADE;
DROP TABLE IF EXISTS Paper CASCADE;
DROP TABLE IF EXISTS Keyword CASCADE;

CREATE TABLE Conference (id SERIAL PRIMARY KEY, name TEXT UNIQUE);

CREATE TABLE Paper (id INT PRIMARY KEY, title TEXT);

CREATE TABLE Keyword (id SERIAL PRIMARY KEY, value TEXT UNIQUE);

CREATE TABLE PaperKeyword (
	paper_id INT NOT NULL REFERENCES Paper,
	keyword_id INT NOT NULL REFERENCES Keyword);

CREATE TABLE PaperConference (
  paper_id INT NOT NULL REFERENCES Paper,
  conference_id INT NOT NULL REFERENCES Conference,
  accepted BOOLEAN,
  UNIQUE(paper_id, conference_id));

INSERT INTO Conference(id, name) VALUES (1, 'SIGMOD'), (2, 'VLDB');
INSERT INTO Keyword(id, value) VALUES (1, 'java'), (2, 'python'), (3, 'sql');
INSERT INTO Paper(id, title) VALUES (1, 'Of Humans'), (2, 'Of Cats'), (3, 'Of Dogs'), (4,'Of Trees');
INSERT INTO PaperKeyword(paper_id, keyword_id) VALUES 
       (1, 1), (1, 2),
       (2, 3),
       (4, 1), (4, 3);
INSERT INTO PaperConference(paper_id, conference_id) VALUES
       (1, 1), (1, 2),
       (2, 1),
       (3, 1),
       (4, 1), (4, 2);

SELECT COUNT(*) AS PaperCount, MAX(PC.paper_id) AS MaxPaperId, C.name AS ConferenceName
FROM PaperConference PC JOIN Conference C ON PC.conference_id = C.id 
GROUP BY PC.conference_id, C.name;

SELECT PaperCount, C.name AS ConferenceName FROM
(SELECT COUNT(*) AS PaperCount, conference_id FROM PaperConference GROUP BY conference_id) AS PCG
JOIN Conference C ON C.id = PCG.conference_id;


CREATE OR REPLACE VIEW PaperCounts AS
SELECT conference_id, COUNT(*) AS paper_count
FROM PaperConference GROUP BY conference_id;
SELECT * FROM PaperCounts;

CREATE OR REPLACE VIEW KeywordCounts AS
SELECT P.id AS paper_id,
       -- COUNT(PK.keyword_id) AS kw_count  -- will count non-NULL keyword_id`s
       SUM(CASE WHEN PK.keyword_id IS NOT NULL THEN 1 ELSE 0 END) AS kw_count
FROM Paper P LEFT JOIN PaperKeyword PK ON P.id = PK.paper_id
GROUP BY P.id;
SELECT * FROM KeywordCounts;


SELECT BigConfs.conference_id, paper_count, KwPerPaper.paper_id, kw_count, accepted
FROM (SELECT conference_id, COUNT(*) AS paper_count
      FROM PaperConference
      GROUP BY conference_id
      HAVING COUNT(*) > 2) BigConfs
JOIN (SELECT T.paper_id, T.kw_count, PC.conference_id, PC.accepted
      FROM (SELECT P.id as paper_id,
            SUM(CASE WHEN PK.keyword_id IS NULL THEN 0 ELSE 1 END) AS kw_count
            FROM Paper P LEFT OUTER JOIN PaperKeyword PK ON P.id = PK.paper_id
            GROUP BY P.id) T
      JOIN PaperConference PC ON T.paper_id = PC.paper_id) KwPerPaper
ON BigConfs.conference_id = KwPerPaper.conference_id
WHERE KwPerPaper.kw_count < 2
ORDER BY 1, 3;

SELECT PQ.conference_id, paper_count, PC.paper_id, kw_count, accepted 
FROM PaperCounts PQ
JOIN PaperConference PC ON PQ.conference_id = PC.conference_id
JOIN KeywordCounts KC ON PC.paper_id = KC.paper_id
WHERE kw_count < 2 AND paper_count > 2
ORDER BY 1,3;

WITH
	SubmittedPapers AS (
		SELECT conference_id, COUNT(*) AS paper_count
		FROM PaperConference GROUP BY conference_id),
	KwPerPaper AS (
		SELECT P.id AS paper_id,
		       COUNT(PK.keyword_id) AS kw_count
		FROM Paper P LEFT OUTER JOIN PaperKeyword PK ON P.id = PK.paper_id
		GROUP BY P.id)
SELECT SP.conference_id, paper_count, PC.paper_id, kw_count, PC.accepted 
FROM SubmittedPapers SP
JOIN PaperConference PC ON SP.conference_id = PC.conference_id
JOIN KwPerPaper KP ON PC.paper_id = KP.paper_id
WHERE paper_count > 2 AND kw_count < 2;
ORDER BY 1,3;


SELECT P.id AS paper_id,
       SUM(CASE WHEN PK.keyword_id IS NOT NULL THEN 1 ELSE 0 END) AS kw_count
FROM Paper P LEFT JOIN PaperKeyword PK ON P.id = PK.paper_id
GROUP BY P.id;

SELECT PK.paper_id AS paper_id,
       SUM(CASE WHEN PK.keyword_id IS NOT NULL THEN 1 ELSE 0 END) AS kw_count
FROM Paper P LEFT JOIN PaperKeyword PK ON P.id = PK.paper_id
GROUP BY PK.paper_id;
