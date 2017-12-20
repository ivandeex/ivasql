/*
 * Задача:
 *     https://stepik.org/lesson/50186/step/5?unit=28718
 * 
 * Это задание рекомендуется решать с помощью оконных функций.
 * Вам может пригодиться документация:
 *     https://postgrespro.ru/docs/postgrespro/9.5/functions-window.html
 * 
 * Позанимаемся анализом биржевых котировок.
 * У вас есть таблица
 *     StockQuotes(company TEXT, week INT, share_price INT).
 * Строка в этой таблице говорит о том, что стоимость акции компании company
 * в неделю номер week составляла share_price.
 * 
 * Назовём индексом в данную неделю среднее арифметическое роста стоимости
 * одной акции по всем компаниям сравнительно с предыдущей неделей.
 * То есть, если одна акция компании A подорожала на 100 единиц,
 * а акция компании B подешевела на 50 единиц, то индекс равен 25.
 * 
 * Назовём компанию успешной на этой неделе, если изменение стоимости одной
 * её акции было выше индекса. "Изменение D выше индекса I" означает "D > I"
 * как вещественное число.
 * 
 * Если компания была успешной три недели подряд то будем говорить, что
 * она сделала успешную серию. Успешные серии могут пересекаться. Так, если
 * компания была успешной 5 недель подряд, то у неё было 3 успешных серии.
 * 
 * Вам нужно посчитать для каждой компании количество успешных серий и вывести
 * в результат два столбца. В первом столбце с типом TEXT должно быть название
 * компании, а во втором с типом BIGINT количество её успешных серий.
 * 
 * Компании, у которых не было успешных серий, выводить в результат не надо совсем.
 *   - Все компании различные.
 *   - Все цены положительные.
 *   - Нумерация недель начинается с 0. На неделе номер 0, разумеется, не определены
 *     рост и индекс -- вы можете считать что они 0, NULL или просто игнорировать
 *     нулевую неделю тем или иным способом при расчёте успешных недель.
 */

DROP TABLE IF EXISTS StockQuotes CASCADE;

CREATE TABLE StockQuotes(
	company TEXT,
	week INT,
	share_price INT
);


DO $$
DECLARE
	setup_method TEXT := 'fixed';
BEGIN
	IF setup_method = 'random' THEN
		PERFORM setseed(0.9);
		INSERT INTO StockQuotes (company, week, share_price)
		SELECT (ARRAY['yahoo','ibm','ford'])[comp],  week, (random()*comp*300+1)::int
		FROM generate_series(0,48) week_t(week), generate_series(1,3) comp_t(comp);
	ELSE -- fixed
		/* Основа для экспериментов:
		 *  20 недель, 3 компании.
		 * Акции первой растут большую часть времени, акции ﻿второй ﻿стоят на месте,
		 * акции третьей плавно снижаются и делают одну попытку ﻿роста.
		 * Правильный запрос выведет строки:
		 *   company  | series
		 * -----------+--------
		 *  Apple     |       9
		 *  Microsoft |       1
		 */ 
		INSERT INTO StockQuotes (company, week, share_price) VALUES
			('Apple',      1,  10),  ('Apple',      2,  15),  ('Apple',      3,  20),  ('Apple',      4,  25),  ('Apple',      5,   30),
			('Apple',      6,  35),  ('Apple',      7,  40),  ('Apple',      8,  45),  ('Apple',      9,  50),  ('Apple',     10,   60),
			('Apple',     11,  70),  ('Apple',     12,  80),  ('Apple',     13,  90),  ('Apple',     14,  90),  ('Apple',     15,  100),
			('Apple',     16, 100),  ('Apple',     17, 100),  ('Apple',     18, 100),  ('Apple',     19, 100),  ('Apple',     20,   90),
			('Oracle',     1,  10),  ('Oracle',     2,  10),  ('Oracle',     3,  10),  ('Oracle',     4,  10),  ('Oracle',     5,   10),
			('Oracle',     6,  10),  ('Oracle',     7,  10),  ('Oracle',     8,  10),  ('Oracle',     9,  10),  ('Oracle',    10,   10),
			('Oracle',    11,  10),  ('Oracle',    12,  10),  ('Oracle',    13,  10),  ('Oracle',    14,  10),  ('Oracle',    15,   10),
			('Oracle',    16,  10),  ('Oracle',    17,  10),  ('Oracle',    18,  10),  ('Oracle',    19,  10),  ('Oracle',    20,   10),
			('Microsoft',  1,  100), ('Microsoft',  2,   95), ('Microsoft',  3,   95), ('Microsoft',  4,   90), ('Microsoft',  5,   90),
			('Microsoft',  6,   85), ('Microsoft',  7,   80), ('Microsoft',  8,  100), ('Microsoft',  9,  120), ('Microsoft',  10, 150),
			('Microsoft',  11, 100), ('Microsoft',  12,  90), ('Microsoft',  13,  90), ('Microsoft',  14,  85), ('Microsoft',  15,  80),
			('Microsoft',  16,  75), ('Microsoft',  17,  70), ('Microsoft',  18,  70), ('Microsoft',  19,  65), ('Microsoft',  20,  60);
	END IF;
END $$;


WITH
    Movements AS (
        SELECT company, week,
               share_price - lag(share_price) OVER company_weeks AS move
        FROM StockQuotes WINDOW company_weeks AS (PARTITION BY company ORDER BY week)
    ),
    Successes AS (
        SELECT company, week, move,
               (move > AVG(move) OVER (PARTITION BY week)) AS success
        FROM Movements
    ),
    Assertions AS (
        SELECT company, week,
               EVERY(COALESCE(success, FALSE)) OVER few_weeks AS all_good
        FROM Successes
        WINDOW few_weeks AS (PARTITION BY company ORDER BY week ROWS 2 PRECEDING)
    )
SELECT company, COUNT(*) AS success_count
FROM Assertions WHERE all_good
GROUP BY company HAVING COUNT(*) > 0
ORDER BY success_count DESC;


/* debugging */
WITH
    Movements AS (
        SELECT company, week,
               share_price - lag(share_price) OVER company_weeks AS move
        FROM StockQuotes WINDOW company_weeks AS (PARTITION BY company ORDER BY week)
    ),
    Indexes AS (
        SELECT *, AVG(move) OVER (PARTITION BY week) AS indx
        FROM Movements
    ),
    Assertions AS (
        SELECT *,
               (move > indx) AS this_week,
               array_agg(move > indx) OVER few_weeks AS week_details,
               every(COALESCE(move > indx, FALSE)) OVER few_weeks AS all_good
        FROM Indexes
        WINDOW few_weeks AS (PARTITION BY company ORDER BY week ROWS 2 PRECEDING)
    )
SELECT * FROM Assertions
ORDER BY company, week;
/* debugging */
