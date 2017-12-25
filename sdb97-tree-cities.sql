DROP TABLE IF EXISTS Cities;
CREATE TABLE Cities(
  id INT PRIMARY KEY,
  value TEXT
);
DELETE FROM Cities;
--INSERT INTO Cities(id, value) VALUES (1, 'Воркута'), (0, 'Джамбул'), (2, 'Львов');
INSERT INTO Cities(id, value) VALUES
  (1, 'А_б'), (2, 'А_в'), (3, 'А_г'),
  (4, 'Б_а'), (5, 'Б_в'), (6, 'Б_г'),
  (7, 'В_а'), (8, 'В_б'), (9, 'В_г'),
  (10,'Г_а'), (11,'Г_б'), (0, 'Г_в');

WITH RECURSIVE Prev(id, value, num, visited) AS (
    SELECT id, value, 1, ARRAY[0] FROM Cities WHERE id=0
  UNION ALL ( /* brackets make LIMIT go into inner query */
    SELECT c.id, c.value, p.num+1, p.visited || c.id
    FROM Prev p JOIN Cities c ON right(p.value,1) = lower(left(c.value,1))
    WHERE c.id != ALL(p.visited)
    LIMIT 1
  )
) SELECT id, value, num FROM Prev;
