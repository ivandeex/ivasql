CREATE OR REPLACE LANGUAGE plpython3u;

DROP TABLE IF EXISTS Conference CASCADE;
DROP TABLE IF EXISTS Paper CASCADE;


CREATE TABLE Conference(
	id SERIAL PRIMARY KEY,
	name TEXT UNIQUE
);

CREATE TABLE Paper(
	id SERIAL PRIMARY KEY,
	title TEXT,
	conference_id INT REFERENCES Conference,
	keywords TEXT[],
	accepted BOOLEAN
);


DROP FUNCTION IF EXISTS array_random;
CREATE OR REPLACE FUNCTION array_random(arr anyarray) RETURNS anynonarray AS $$
BEGIN
	RETURN arr[(random() * (array_upper(arr, 1) - 1))::integer + 1];
END
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS SetupConferencesPapersTables();
CREATE OR REPLACE FUNCTION SetupConferencesPapersTables() RETURNS TEXT AS $$
DECLARE
	MAX_CONF_ CONSTANT integer := 200;
	MAX_PAPER_ CONSTANT integer := 5000;
	MAX_TITLE_ CONSTANT integer := 8;
	MAX_KEYWORDS_ CONSTANT integer := 5;

	conf_names_ text[] := array[
		'AAMAS', 'ACCV', 'ACL', 'ACMMM', 'ACT', 'ASIACRYPT', 'ASPLOS', 'BHI',
		'BMVC', 'CAV', 'CCS', 'CDC', 'CEC', 'CHI', 'CIKM', 'CLOUD', 'COLING',
		'COLT', 'CoNEXT', 'CRYPTO', 'CSCW', 'CVPR', 'DAC', 'DATE', 'EC',
		'ECCV', 'EMNLP', 'ESWC', 'EUROCRYPT', 'EuroSys', 'FAST', 'FC', 'FOCS',
		'FSE', 'GLOBECOM', 'HICSS', 'HPCA', 'HRI', 'ICASSP', 'ICC', 'ICCV',
		'ICDCS', 'ICDE', 'ICDM', 'ICIP', 'ICML', 'ICPR', 'ICRA', 'ICSE',
		'ICWSM', 'IJCAI', 'IMC', 'INFOCOM', 'INTERSPEECH', 'IPDPS', 'IROS',
		'ISCA', 'ISIT', 'ISSCC', 'ISWC', 'LREC', 'MICCAI', 'MICRO', 'MobiCom',
		'MSR', 'NDSS', 'NIPS', 'NSDI', 'OOPSLA', 'OSDI', 'PACT', 'PLDI',
		'POPL', 'PPOPP', 'RSS', 'SC', 'SDM', 'Security', 'SIGCOMM', 'SIGIR',
		'SIGKDD', 'SIGMOD', 'SODA', 'SP', 'STOC', 'TACAS', 'TCC', 'UbiComp',
		'UIST', 'USENIX', 'VLDB', 'VTC', 'WSDM'
	];
	lorem_ipsum_ text[] := array[
		'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
		'elit', 'a', 'ac', 'accumsan', 'ad', 'aenean', 'aliquam', 'aliquet',
		'ante', 'aptent', 'arcu', 'at', 'auctor', 'augue', 'bibendum',
		'blandit', 'class', 'commodo', 'condimentum', 'congue', 'consequat',
		'conubia', 'convallis', 'cras', 'cubilia', 'cum', 'curabitur',
		'curae', 'cursus', 'dapibus', 'diam', 'dictum', 'dictumst',
		'dignissim', 'dis', 'donec', 'dui', 'duis', 'egestas', 'eget',
		'eleifend', 'elementum', 'enim', 'erat', 'eros', 'est', 'et', 'etiam',
		'eu', 'euismod', 'facilisi', 'facilisis', 'fames', 'faucibus', 'felis',
		'fermentum', 'feugiat', 'fringilla', 'fusce', 'gravida', 'habitant',
		'habitasse', 'hac', 'hendrerit', 'himenaeos', 'iaculis', 'id',
		'imperdiet', 'in', 'inceptos', 'integer', 'interdum', 'justo',
		'lacinia', 'lacus', 'laoreet', 'lectus', 'leo', 'libero', 'ligula',
		'litora', 'lobortis', 'luctus', 'maecenas', 'magna', 'magnis',
		'malesuada', 'massa', 'mattis', 'mauris', 'metus', 'mi', 'molestie',
		'mollis', 'montes', 'morbi', 'mus', 'nam', 'nascetur', 'natoque',
		'nec', 'neque', 'netus', 'nibh', 'nisi', 'nisl', 'non', 'nostra',
		'nulla', 'nullam', 'nunc', 'odio', 'orci', 'ornare', 'parturient',
		'pellentesque', 'penatibus', 'per', 'pharetra', 'phasellus',
		'placerat', 'platea', 'porta', 'porttitor', 'posuere', 'potenti',
		'praesent', 'pretium', 'primis', 'proin', 'pulvinar', 'purus', 'quam',
		'quis', 'quisque', 'rhoncus', 'ridiculus', 'risus', 'rutrum',
		'sagittis', 'sapien', 'scelerisque', 'sed', 'sem', 'semper',
		'senectus', 'sociis', 'sociosqu', 'sodales', 'sollicitudin',
		'suscipit', 'suspendisse', 'taciti', 'tellus', 'tempor', 'tempus',
		'tincidunt', 'torquent', 'tortor', 'tristique', 'turpis',
		'ullamcorper', 'ultrices', 'ultricies', 'urna', 'ut', 'varius',
		'vehicula', 'vel', 'velit', 'venenatis', 'vestibulum', 'vitae',
		'vivamus', 'viverra', 'volutpat', 'vulputate'
	];
	year_ integer;
	suffix_ text;
	title_ text;
	word_ text;
	keywords_ text[];
	conf_id_ integer;
	all_ids_ integer[];
	max_ integer;
BEGIN
	DELETE FROM Paper;
	DELETE FROM Conference;

	WHILE (SELECT COUNT(*) FROM Conference) < MAX_CONF_ LOOP
		year_ := (random() * (2017 - 1970) + 1970)::int;
		suffix_ := lpad(mod(year_, 100)::text, 2, '0');
		title_ := format('%s''%s', array_random(conf_names_), suffix_);
		BEGIN
			INSERT INTO Conference (name) VALUES (title_);
		EXCEPTION
			WHEN unique_violation THEN NULL;
		END;
	END LOOP;

	all_ids_ := array(SELECT id FROM Conference ORDER BY 1);

	WHILE (SELECT COUNT(*) FROM Paper) < MAX_PAPER_ LOOP
		max_ := (random() * MAX_TITLE_ + 1)::integer;
		title_ := '';
		FOR i IN 1..max_ LOOP
			word_ := array_random(lorem_ipsum_);
			IF i = 1 THEN word_ := initcap(word_); END IF;
			title_ := title_ || ' ' || word_;
		END LOOP;
		title_ := trim(both ' ' from title_);

		max_ := (random() * MAX_KEYWORDS_ + 1)::integer;
		keywords_ := array[]::text[];
		WHILE coalesce(array_length(keywords_, 1), 0) < max_ LOOP
			word_ := array_random(lorem_ipsum_);
			CONTINUE WHEN word_ = ANY(keywords_);
			keywords_ := array_append(keywords_, word_);
		END LOOP;

		conf_id_ := array_random(all_ids_);
		BEGIN
			INSERT INTO Paper(title, conference_id, keywords, accepted)
				VALUES (title_, conf_id_, keywords_, false);
		EXCEPTION
			WHEN unique_violation THEN NULL;
		END;
	END LOOP;

	RETURN 'OK';
END
$$ LANGUAGE plpgsql;


SELECT SetupConferencesPapersTables();
SELECT * FROM Conference;
SELECT * FROM Paper;
