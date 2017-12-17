DROP TABLE IF EXISTS Conference CASCADE;
DROP TABLE IF EXISTS ConferenceEvent CASCADE;
DROP TABLE IF EXISTS Paper CASCADE;
DROP VIEW IF EXISTS HighPaperAcceptance;


CREATE TABLE Conference(
  id INT PRIMARY KEY,
  name TEXT UNIQUE
);

CREATE TABLE ConferenceEvent(
  id SERIAL PRIMARY KEY,
  conference_id INT, -- REFERENCES Conference,
  year INT,
  UNIQUE(conference_id, year)
);

CREATE TABLE Paper(
  id INT PRIMARY KEY,
  event_id INT, -- REFERENCES ConferenceEvent,
  title TEXT,
  accepted BOOLEAN
);

CREATE TABLE Reviewer(
  id INT PRIMARY KEY,
  email TEXT UNIQUE,
  name TEXT
);

CREATE TABLE PaperReviewing(
  paper_id INT, -- REFERENCES Paper,
  reviewer_id INT, -- REFERENCES Reviewer,
  score INT,
  UNIQUE(paper_id, reviewer_id)
);

INSERT INTO Conference(id, name) VALUES (1, 'SIGMOD'), (2, 'VLDB');
INSERT INTO ConferenceEvent(conference_id, year) VALUES (1, 2015), (1, 2016), (2, 2016);
INSERT INTO Reviewer(id, email, name) VALUES
  (1, 'jennifer@stanford.edu', 'Jennifer Widom'),
  (2, 'donald@ethz.ch', 'Donald Kossmann'),
  (3, 'jeffrey@stanford.edu', 'Jeffrey Ullman'),
  (4, 'jeff@google.com', 'Jeffrey Dean'),
  (5, 'michael@mit.edu', 'Michael Stonebraker');

INSERT INTO Paper(id, event_id, title) VALUES
  (1, 1, 'Paper1'),
  (2, 2, 'Paper2'),
  (3, 2, 'Paper3'),
  (4, 3, 'Paper4');

INSERT INTO PaperReviewing(paper_id, reviewer_id) VALUES
  (1, 1), (1, 4), (1, 5),
  (2, 1), (2, 2), (2, 4),
  (3, 3), (3, 4), (3, 5),
  (4, 2), (4, 3), (4, 4);


CREATE OR REPLACE FUNCTION
    SubmitReview(_paper_id INT, _reviewer_id INT, _score INT) RETURNS VOID
AS $$
DECLARE
	num_scores INT;
	avg_score REAL;
	old_result BOOLEAN;
BEGIN
	IF _score NOT BETWEEN 1 AND 7 THEN
		RAISE SQLSTATE 'DB017' USING HINT = 'invalid score';
	END IF;
	SELECT accepted INTO STRICT old_result FROM Paper WHERE id = _paper_id;
	IF old_result IS NOT NULL THEN
		RAISE SQLSTATE 'DB017' USING HINT = 'cannot change decision after (not) accepting';
	END IF;
	UPDATE PaperReviewing SET score = _score
		WHERE paper_id = _paper_id AND reviewer_id = _reviewer_id;
	IF NOT FOUND THEN
		RAISE SQLSTATE 'DB017' USING HINT = 'review not found';
	END IF;
	SELECT COUNT(*), AVG(score) INTO num_scores, avg_score FROM PaperReviewing
		WHERE paper_id = _paper_id AND score IS NOT NULL;
	IF num_scores = 3 THEN
		UPDATE Paper SET accepted = (avg_score > 4)::BOOL
			WHERE id = _paper_id;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE SQLSTATE 'DB017' USING HINT = 'other error happened';
END
$$ LANGUAGE plpgsql;


SELECT SubmitReview(1,4,0);
SELECT * FROM PaperReviewing WHERE paper_id = 1;
SELECT * FROM Paper WHERE id = 1;
