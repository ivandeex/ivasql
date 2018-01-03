DROP TABLE IF EXISTS Keyword CASCADE;
DROP TABLE IF EXISTS PaperKeyword CASCADE;

CREATE TABLE Keyword (id INT PRIMARY KEY, value TEXT);
CREATE TABLE PaperKeyword(paper_id INT, keyword_id INT REFERENCES Keyword);

INSERT INTO Keyword (id) VALUES (1),(2),(3),(4);

INSERT INTO PaperKeyword (keyword_id, paper_id) VALUES
	(1,1), (1,2), (1,3), (1,4), (1,5),
	(3,1),
	(4,1), (4,2), (4,3);

SELECT id FROM Keyword WHERE NOT EXISTS (SELECT 1 FROM PaperKeyword WHERE keyword_id = id);
SELECT id FROM Keyword WHERE id NOT IN (SELECT keyword_id FROM PaperKeyword);

SELECT id, keyword_id, paper_id
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id;

SELECT id, COUNT(keyword_id)
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id
GROUP BY id ORDER BY id;

SELECT id, COUNT(*)
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id
GROUP BY id ORDER BY id;

SELECT id
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id
GROUP BY id HAVING COUNT(keyword_id) = 0 ORDER BY id;

SELECT id
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id
GROUP BY id HAVING COUNT(*) = 0 ORDER BY id;

SELECT id, keyword_id
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id
GROUP BY id, keyword_id ORDER BY id;

SELECT id
FROM Keyword LEFT OUTER JOIN PaperKeyword ON id = keyword_id
GROUP BY id, keyword_id HAVING keyword_id IS NULL ORDER BY id;
