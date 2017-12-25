-- hierarchy table
DROP TABLE IF EXISTS Keyword CASCADE;
CREATE TABLE Keyword(
  id INT PRIMARY KEY, 
  value TEXT, -- некое значение, не имеющее смысла для целей этой задачи
  parent_id INT REFERENCES Keyword DEFAULT NULL
);


-- simple test data
TRUNCATE TABLE Keyword; 
INSERT INTO Keyword (id, parent_id, value) VALUES                    
	(0, NULL, 'qwerty'), (1, 0, 'asdfg'), (2, 0, 'zxcvb'), (3, 1, 'yuiop'), (4, 1, 'ghjkl');


CREATE OR REPLACE FUNCTION
InsertKeyword(vertex_id INT, _parent_id INT, _value TEXT) RETURNS INT
AS $$
DECLARE
	_result INT;
BEGIN
	INSERT INTO Keyword(id, value, parent_id) VALUES (vertex_id, _value, _parent_id) RETURNING id INTO _result;
	RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Процедура генерирует случайное дерево из N вершин
CREATE OR REPLACE FUNCTION
GenerateData(N int) RETURNS VOID
AS $$
DECLARE
	_id INT;
	_parent_id INT;
	_value TEXT;
BEGIN
	PERFORM InsertKeyword(0, NULL, 'root');
	FOR _id IN 1 .. N-1 LOOP
		_parent_id = floor((random()*_id));
		_value = md5(random()::TEXT);
		PERFORM InsertKeyword(_id, _parent_id, _value);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


TRUNCATE TABLE Keyword; 
SELECT GenerateData(150000);


-- using arrays (33-44s)
WITH RECURSIVE Parents(id, parents) AS (
	SELECT id, array[id] FROM Keyword WHERE parent_id IS NULL
  UNION ALL
	SELECT K.id, P.parents || K.id
	FROM Keyword K
	JOIN Parents P ON K.parent_id = P.id
)
SELECT K.id AS id,
       array_length(array_agg(P.id),1)::BigInt AS subtree_size
FROM Keyword K JOIN Parents P ON K.id = any(P.parents)
GROUP BY K.id
ORDER BY 2 DESC;


-- without arrays (20-24s)
WITH RECURSIVE Tree(cid, pid) AS (
	SELECT id, id FROM Keyword
  UNION ALL
	SELECT id, pid
	FROM Keyword
	JOIN Tree ON parent_id = cid
)
SELECT pid AS id, COUNT(*) AS subtree_size
FROM Tree
GROUP BY pid
ORDER BY 2 DESC;
