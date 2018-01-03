DROP TABLE IF EXISTS T;
CREATE TABLE T (id INT PRIMARY KEY, value INT);
DELETE FROM T;
INSERT INTO T (id,value) VALUES (5,3), (11,3), (3,3), (22,1), (32,2), (7,100500), (9,1233456789);

-- imitation of RANK()
SELECT Curr.id, Curr.value, COUNT(Prev.id) AS seqno
FROM T AS Curr LEFT OUTER JOIN T AS Prev
ON Prev.value < Curr.value OR (Prev.value = Curr.value AND Prev.id < Curr.id)
GROUP BY Curr.id ORDER BY seqno;

-- without GROUP BY...
SELECT id, value,
       (SELECT COUNT(1) FROM T WHERE value < Cur.value OR (value = Cur.value AND id < Cur.id)) AS seqno
FROM T AS Cur ORDER BY seqno;

-- final query
SELECT value AS median, size
FROM (SELECT (SELECT COUNT(1) FROM T
              WHERE value < Cur.value OR (value = Cur.value AND id < Cur.id)) AS seqno,
             value FROM T AS Cur) AS Ord
JOIN (SELECT COUNT(1) AS size FROM T) AS ConstSize
ON seqno = (size - 1)/2;

/* Нам надо как-то пронумеровать элементы в порядке увеличения значения с учётом
 * того, что значения могут повторяться. Для этого мы делаем подзапрос, где
 * подсчитываем количество элементов с меньшим значением или с таким же, но
 * с меньшим id (он не может совпадать, т.к. уникален). Так мы получаем псевдополе
 * seqno в диапазоне от 0 до (size-1). Чтобы сократить код запроса и два раза
 * не считать COUNT(*) по всей таблице, заводим вторую псевдотаблицу CostSize
 * с единственным строкой, в которой он лежит. Из полученного джойна (точнее,
 * декартова произведения) выбираем только одну строку, в которой seqno лежит
 * ровно посередине. Вроде коротко получилось.
 */

-- simpler query
-- note: it's wrong, it breaks if the median value is repeated
SELECT value AS median, size
FROM (SELECT (SELECT COUNT(1) FROM T WHERE value <= Cur.value) AS seqno, value FROM T AS Cur) AS Ord
JOIN (SELECT COUNT(1) AS size FROM T) AS ConstSize
ON seqno = size/2 + 1;


-- variant from vlad petrigo
-- see: https://stepik.org/lesson/50186/step/3?discussion=508748&thread=solutions
-- note: it's wrong, it returns several rows
WITH count_less AS 
    (SELECT T1.value, COUNT(*) AS sorted_id 
     FROM T AS T1  JOIN  T AS T2  ON (T1.value >= T2.value) 
     GROUP BY T1.value),
    elems_cnt AS (SELECT COUNT(*) as cnt FROM T)
SELECT value, cnt FROM count_less, elems_cnt WHERE sorted_id = cnt / 2 + 1;

-- variant with "greater" vs "less" table
SELECT T1.value, count(1) as count
      FROM T AS T1 LEFT JOIN T AS T2
      ON T1.value > T2.value GROUP BY T1.value;
SELECT T1.value, count(1) as count
        FROM T AS T1 LEFT JOIN T AS T2
        ON T1.value < T2.value GROUP BY T1.value;

SELECT GR.value as median, GR.count * 2 + 1 as size
FROM (SELECT T1.value, count(1) as count
      FROM T AS T1 LEFT JOIN T AS T2
      ON T1.value > T2.value GROUP BY T1.value) as GR
  JOIN (SELECT T1.value, count(1) as count
        FROM T AS T1 LEFT JOIN T AS T2
        ON T1.value < T2.value GROUP BY T1.value) as LS
ON GR.count = LS.count AND GR.value = LS.value;

-- official postgres solution
SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY value) AS median, COUNT(*) AS size FROM T; 

-- official solution for sqlite with extensions 
-- SELECT MEDIAN(value) AS median, COUNT(value) AS size FROM T;

