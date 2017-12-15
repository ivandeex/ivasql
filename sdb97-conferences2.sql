DROP TABLE IF EXISTS PaperSubmission;
DROP TABLE IF EXISTS Venue;
DROP TABLE IF EXISTS Conference;

-- Название конференции, без года (например 'SIGMOD') и описание
CREATE TABLE Conference(
    name TEXT PRIMARY KEY,
    description TEXT
);

-- Площадка для проведения конференции, представляющая из себя большое здание. 
-- Разные площадки расположены в разных зданиях.
-- У площадки есть имя (например, 'Кремлевский Дворец Съездов'),
-- город, в котором она расположена, страна, и географические координаты с точностью до 5 знаков 
-- после запятой, что соответствует единицам метров на местности в средних широтах
CREATE TABLE Venue(
    id INTEGER PRIMARY KEY,
    name TEXT,
    city TEXT,
    country TEXT,
    lat NUMERIC(7,5),
    lon NUMERIC(8,5),
    UNIQUE (lat, lon)
);

-- Статья, принятая на конференцию и опубликованная в трудах конференции
-- Строка в таблице утверждает, что статья с названием title была опубликована в трудах 
-- конференции conference, проходившей на площадке venue_id в year году, 
-- трудам был присвоен isbn код, и статью следует искать на странице page
CREATE TABLE PaperSubmission(
  id INTEGER PRIMARY KEY,
  conference TEXT,
  year INTEGER,
  title TEXT,
  isbn TEXT,
  page INTEGER,
  venue_id INTEGER,
  FOREIGN KEY (conference) REFERENCES Conference(name),
  FOREIGN KEY (venue_id) REFERENCES Venue(id),
  UNIQUE (title, conference, year),
  UNIQUE (isbn, page)
);
