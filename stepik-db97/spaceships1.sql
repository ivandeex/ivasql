DROP TABLE IF EXISTS Planet CASCADE;
DROP TABLE IF EXISTS Flight CASCADE;
DROP TABLE IF EXISTS Commander CASCADE;

CREATE TABLE Planet(
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE,
  distance NUMERIC(5,2),
  galaxy INT CHECK(galaxy > 0)
);

CREATE TABLE Commander(
  id SERIAL PRIMARY KEY,
  name TEXT
);

CREATE TABLE Flight(
  id INT PRIMARY KEY,
  planet_id INT REFERENCES Planet,
  commander_id INT REFERENCES Commander,
  start_date DATE,
  UNIQUE(commander_id, start_date)
);

SELECT (COALESCE((SELECT COUNT(1) FROM Planet), 0) +
                 GREATEST(COALESCE((SELECT MAX(n) FROM
                                      (SELECT count(1) n FROM Flight GROUP BY planet_id) Counts_),
                                   0),
                          1::BIGINT)) AS cnt;

SELECT (SELECT COUNT(1) FROM Planet WHERE galaxy = 2)  -- no. of planets
        + MAX(n) FROM                   -- max no. of flights per planet
        (SELECT COUNT(1) n FROM Flight
         WHERE planet_id IN (SELECT id FROM Planet WHERE galaxy = 2)
         GROUP BY planet_id) FlightsPerPlanet;
