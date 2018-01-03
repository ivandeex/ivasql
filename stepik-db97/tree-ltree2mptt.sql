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
		_value = right(md5(random()::text),4);
		PERFORM InsertKeywordLtree(_id, _parent_id, _value);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- big random dataset
TRUNCATE TABLE KeywordLtree;
SELECT GenerateData(15);

-- small test dataset
TRUNCATE TABLE KeywordLtree;
INSERT INTO KeywordLtree (id, value, path) VALUES
  (0, '[1-16]', '1'),
  (2, '[2-9]', '1.2'), (3, '[3-4]', '1.2.3'), (555, '[5-6]', '1.2.5'), (7, '[7-8]', '1.2.7'),
  (10, '[10-15]', '1.10'), (11, '[11-12]', '1.10.11'), (13, '[13-14]', '1.10.13');

SELECT * FROM KeywordLtree ORDER BY id;

/*
 * Пользуемся тем, что:
 * 1. у любого узла $rgt = lft+2 \cdot N_{children} − 1$, где $N_{children}$ -- это число детей + сам узел.
 * 2. у самого левого непосредственного ребёнка $lft(left\_child) = lft(parent) + 1$.
 * 3. между детьми одного родителя значение $\sum N_{children}$ накапливается по мере роста $id$.
 * 4. путь до родителя равен $subpath(child.path,0,-1)$ для всех узлов кроме $id=0$ (корня).
 *
 * Моё решение не такое краткое, как решения от *Vladimir Petrigo* или *Poul Pletnev* ниже,
 * но в отличие от них оно не использует формулу $lft = absolute\_position * 2 - level$,
 * которая корректно работает только при упорядочении узлов по $path$ лексикографически.
 * Из-за этого данные решения упорядочат детские узлы под родительским по их $path$,
 * а не по $id$, как требуется в условии.
 */
WITH RECURSIVE Children AS (
    SELECT P.*, 2 * count(*) AS nch2
    FROM KeywordLtree P  JOIN KeywordLtree C ON P.path @> C.path
    GROUP BY P.id
), Parents AS (
    SELECT *, 1::bigint AS lft  FROM Children WHERE id=0
  UNION ALL
    SELECT C.*, 1 + P.lft + (sum(C.nch2) OVER ChildRow)::bigint - C.nch2 AS lft
    FROM Children C  JOIN Parents P ON C.id<>0 AND P.path = subpath(C.PATH,0,-1)
    WINDOW ChildRow AS (PARTITION BY P.id ORDER BY C.id)
)
SELECT id, value, path,
       lft, lft + nch2 - 1 AS rgt
FROM Parents ORDER BY lft;

/*
 * Aux by Vladimir Petrigo
 * пользуемся тем, что $lft = position_{abs} * 2 - level$
 * считаем children через JOIN, position через оконную функцию,
 * а level вычисляем из path  
 */
WITH Aux AS (
    SELECT P.*, count(*) as children, nlevel(P.path) AS level,
           row_number() OVER (ORDER BY P.path) as position
    FROM KeywordLtree P
    JOIN KeywordLtree C ON P.path @> C.path
    GROUP BY P.id
)
SELECT id, value, path,
       position*2 - level AS lft,
       position*2 - level + children*2 - 1 AS rgt
FROM Aux ORDER BY lft;

/*
 * Kek by Paul Pletnev
 * считаем position/level/children с помощью JOIN
 */
WITH Aux AS(
    SELECT T.id, T.value, T.path,
        sum((T.path @> S.path)::int) as children,
        sum((T.path <@ S.path)::int) as level,
        sum((T.path >= S.path)::int) as position
    FROM KeywordLtree T, KeywordLtree S 
    GROUP BY T.id
)
SELECT id, value, path,
       position*2 - level as lft,
       position*2 - level + children*2 - 1 AS rgt
FROM Aux ORDER BY lft;
