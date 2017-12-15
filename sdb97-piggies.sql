SET lc_messages TO 'ru_RU.UTF8';
--
DROP TABLE IF EXISTS Кормёжка;
DROP TABLE IF EXISTS Поросята;
--
CREATE TABLE Поросята(id SERIAL, вес INT, PRIMARY KEY(id), CHECK(вес>=0));
--INSERT INTO Поросята(вес) VALUES (100),(200),(300);
CREATE TABLE Кормёжка(номер_поросёнка INT, FOREIGN KEY(номер_поросёнка) REFERENCES Поросята(id));
--
BEGIN;
  INSERT INTO Поросята(вес) VALUES (100);
  INSERT INTO Кормёжка(номер_поросёнка) VALUES ((SELECT COUNT(*) FROM Поросята));
COMMIT;
--
BEGIN;
  INSERT INTO Поросята(вес) VALUES (200);
  INSERT INTO Кормёжка(номер_поросёнка) VALUES ((SELECT COUNT(*) FROM Поросята));
COMMIT;

-- в следующей строчке Наина Киевна ошиблась со значением 
BEGIN;
  INSERT INTO Поросята(вес) VALUES (-300);
  INSERT INTO Кормёжка(номер_поросёнка) VALUES ((SELECT COUNT(*) FROM Поросята));
COMMIT;
ROLLBACK;
-- но сразу же тут исправилась и внесла правильное
BEGIN;
  INSERT INTO Поросята(вес) VALUES (300);
  INSERT INTO Кормёжка(номер_поросёнка) VALUES ((SELECT COUNT(*) FROM Поросята));
COMMIT;
ROLLBACK;
--
SELECT (SELECT COUNT(*) FROM Кормёжка) AS "№ Кормёжка",
       (SELECT COUNT(*) FROM Поросята) AS "№ Поросята";
--
