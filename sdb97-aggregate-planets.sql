DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS Planet;
DROP TABLE IF EXISTS PoliticalSystem;
DROP TABLE IF EXISTS TestPlanetsWithFlights;

-- Справочник политических строев
CREATE TABLE PoliticalSystem(id SERIAL PRIMARY KEY, value TEXT UNIQUE);

-- Планета, её название, расстояние до Земли, политический строй
CREATE TABLE Planet(
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE,
  distance NUMERIC(5,2),
  psystem_id INT REFERENCES PoliticalSystem);

-- Полет на планету в означенную дату
CREATE TABLE Flight(id INT PRIMARY KEY,
  planet_id INT REFERENCES Planet,
  date DATE
);

-- Планеты, на которые не совершались полёты, тоже должны попасть в результат.

SELECT planet, psystem,
       rank() OVER (PARTITION BY psystem ORDER BY nflights DESC) AS local_rank,
       rank() OVER (ORDER BY nflights DESC) AS global_rank
FROM (SELECT P.name AS planet, PS.value AS psystem, COUNT(F.planet_id) AS nflights
      FROM Planet P
      LEFT OUTER JOIN Flight F ON P.id = F.planet_id
      JOIN PoliticalSystem PS ON P.psystem_id = PS.id
      GROUP BY P.name, PS.value) AS PF;

-- Короткий тест:

CREATE TABLE TestPlanetsWithFlights(
	planet TEXT PRIMARY KEY,
	psystem INT,
	nflights INT
);

INSERT INTO TestPlanetsWithFlights VALUES
	('A',1,20),('B',1,18),('C',2,17),('D',1,17),
	('E',2,15),('F',2,15),('G',1,15);

SELECT planet, psystem, nflights,
       rank() OVER (PARTITION BY psystem ORDER BY nflights DESC) AS local_rank,
       rank() OVER (ORDER BY nflights DESC) AS global_rank
FROM TestPlanetsWithFlights ORDER BY planet;
