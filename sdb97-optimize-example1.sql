----------------------------------------------------------------------------------

DROP TABLE IF EXISTS Participant CASCADE;
DROP TABLE IF EXISTS Researcher CASCADE;
DROP TABLE IF EXISTS University CASCADE;
DROP TABLE IF EXISTS Conference CASCADE;

----------------------------------------------------------------------------------

CREATE TABLE University(
    university_id SERIAL PRIMARY KEY,
    name TEXT
);
CREATE TABLE Researcher(
    researcher_id SERIAL PRIMARY KEY,
    university_id INT NOT NULL REFERENCES University,
    name TEXT
);
CREATE TABLE Conference(
    conference_id SERIAL PRIMARY KEY,
    name TEXT
);
CREATE TABLE Participant(
    conference_id INT REFERENCES Conference,
    researcher_id INT REFERENCES Researcher,
    UNIQUE (conference_id, researcher_id)
);
CREATE INDEX Participant_Unique ON Participant(conference_id, researcher_id);

----------------------------------------------------------------------------------

INSERT INTO University(name) VALUES ('Stanford');
INSERT INTO University(name)
    SELECT 'University' || (random() * 999999)::int FROM generate_series(1, 100);

INSERT INTO Conference(name) VALUES ('VLDB''15');
INSERT INTO Conference(name)
    SELECT 'Conf' || (random() * 999999)::int FROM generate_series(1, 100);

INSERT INTO Researcher(university_id, name)
    SELECT (random() * 100 + (SELECT min(university_id) FROM University))::int,
           'Person' || (random() * 999999)::int
    FROM generate_series(1, 100000);

----------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS SetupResearcherTable(goal BIGINT);
CREATE OR REPLACE FUNCTION
    SetupResearcherTable(goal BIGINT) RETURNS text
AS $$
DECLARE
    total BIGINT;
    min_conf INT;
    num_conf INT;
    min_resch INT;
    num_resch INT;
    num_iter INT := 0;
    chunk_size BIGINT := 1000;
BEGIN
	SELECT min(conference_id) INTO min_conf FROM Conference;
    SELECT count(*) INTO num_conf FROM Conference;
    SELECT min(researcher_id) INTO min_resch FROM Researcher;
    SELECT count(*) INTO num_resch FROM Researcher;

    LOOP
        num_iter := num_iter + 1;
        EXIT WHEN num_iter > goal / chunk_size * 2;

        SELECT count(*) INTO total FROM Participant;
        EXIT WHEN total >= goal;

        CREATE TEMPORARY TABLE
            TempParticipant(conference_id, researcher_id)
        ON COMMIT DROP
        AS  SELECT (random() * (num_conf - 1) + min_conf)::int,
                   (random() * (num_resch - 1) + min_resch)::int
            FROM generate_series(1, least(goal - total, chunk_size));

        DELETE FROM TempParticipant
            WHERE (conference_id || '/' || researcher_id)
            IN (SELECT conference_id || '/' || researcher_id FROM Participant);

        BEGIN
            INSERT INTO Participant(conference_id, researcher_id)
                SELECT * FROM TempParticipant;
        EXCEPTION
            WHEN unique_violation THEN NULL;
        END;

        DROP TABLE TempParticipant;
    END LOOP;
    RETURN format('finished after %s iterations', num_iter);
END
$$ LANGUAGE plpgsql;

SELECT SetupResearcherTable(1000000);
SELECT COUNT(*) FROM Participant;

----------------------------------------------------------------------------------

UPDATE Researcher
SET university_id = (SELECT university_id FROM University WHERE name='Stanford')
WHERE researcher_id
IN (SELECT researcher_id FROM Participant
    WHERE conference_id = (SELECT conference_id FROM Conference
                           WHERE name='VLDB''15'));

----------------------------------------------------------------------------------

-- these two queries take similar time
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM Conference C
JOIN Participant P USING(conference_id)
JOIN Researcher R USING(researcher_id)
JOIN University U USING(university_id)
WHERE U.name='Stanford' AND C.name='VLDB''15';

EXPLAIN ANALYZE
SELECT COUNT(*)
FROM (SELECT * FROM Conference WHERE name='VLDB''15') C
JOIN Participant P USING(conference_id)
JOIN Researcher R USING(researcher_id)
JOIN (SELECT * FROM University WHERE name='Stanford') U USING(university_id);

---------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS GetParticipantCount(id INT);
CREATE OR REPLACE FUNCTION GetParticipantCount(id INT) RETURNS BIGINT
AS 'SELECT COUNT(*) FROM Participant WHERE conference_id = id' LANGUAGE SQL;
SELECT GetParticipantCount(1);

-- slow query
EXPLAIN ANALYZE
SELECT name, GetParticipantCount(conference_id) AS participant_count
FROM Conference WHERE GetParticipantCount(conference_id) > 7000;

-- fast query
EXPLAIN ANALYZE
SELECT name, COUNT(*) AS participant_count
FROM Conference JOIN Participant USING (conference_id)
GROUP BY Conference.conference_id HAVING COUNT(*) > 7000;

---------------------------------------------------------------------------------
