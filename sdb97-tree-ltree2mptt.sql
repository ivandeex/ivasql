/*
 * Convert ltree-based adjacency list into nested sets (aka MPTT) in a single query
 * 
 * Problem statement:  https://stepik.org/lesson/50193/step/4
 * 
 * Нужно написать запрос, в результате которого будут следующие столбцы, в порядке очередности:
 * id    INT:    идентификатор вершины, такой же как и в таблице KeywordLtree
 * value TEXT:   значение, такое же как и в соответствующей строке в таблице KeywordLrree
 * lft   BIGINT: левый номер вершины
 * rgt   BIGINT: правый номер вершины
 * 
 */

DROP TABLE IF EXISTS KeywordLtree CASCADE;
CREATE TABLE KeywordLtree(
	id INT PRIMARY KEY,
	value TEXT,
	path ltree
);


-- Процедура вставляет новую вершину в дерево в таблице KeywordLtree
CREATE OR REPLACE FUNCTION
	InsertKeywordLtree(_id INT, _parent_id INT, _value TEXT) RETURNS VOID
AS $$
	INSERT INTO KeywordLtree
	SELECT _id AS id, _value AS value, K.path || text2ltree(_id::TEXT) AS path
	FROM KeywordLtree K WHERE id = _parent_id;
$$ LANGUAGE sql;


-- Процедура генерирует случайное дерево из N вершин
CREATE OR REPLACE FUNCTION GenerateData(N int) RETURNS VOID AS $$
DECLARE
  _id INT;
  _parent_id INT;
  _value TEXT;
BEGIN
	INSERT INTO KeywordLtree(id, value, path) VALUES (0, 'root', '');
	FOR _id IN 1..N-1 LOOP
  		_parent_id = floor((random()*_id));
		_value = md5(random()::TEXT);
		PERFORM InsertKeywordLtree(_id, _parent_id, _value);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


TRUNCATE TABLE KeywordLtree; 
SELECT GenerateData(20);


WITH RECURSIVE NumChildren (id, nchildren) AS (
	SELECT P.id, COUNT(*)
	FROM KeywordLtree P
	JOIN KeywordLtree C ON P.path @> C.PATH
	GROUP BY P.id
), Levels (id, path, level, pid, pleft, nchildren) AS (
	SELECT K.id, path, 0, NULL::int, 0, nchildren --, value
	FROM KeywordLtree K
	JOIN NumChildren NC ON K.id = NC.id
	WHERE K.id = 0
  UNION ALL
	SELECT C.id, C.path, P.level + 1, P.id, P.pleft+1, NC.nchildren --, C.value
	FROM KeywordLtree C
	JOIN NumChildren NC ON C.id = NC.id
	JOIN Levels P ON C.path <@ P.path AND nlevel(C.path) = nlevel(P.path)+1  
), LeftValues AS (
	SELECT L.*,
    	   pleft + 1 + coalesce(sum(nchildren) OVER LeftSiblings, 0) * 2 AS lft
	FROM Levels L
	WINDOW LeftSiblings AS (PARTITION BY level ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
), AllValues AS (
	SELECT L.*, lft + nchildren*2 - 1 AS rgt
	FROM LeftValues L
	ORDER BY path
)
SELECT * FROM AllValues;
SELECT id, value, lft, rgt FROM AllValues;
