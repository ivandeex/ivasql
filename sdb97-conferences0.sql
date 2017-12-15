CREATE OR REPLACE LANGUAGE plpython3u;

DROP TABLE IF EXISTS Participant CASCADE;
DROP TABLE IF EXISTS Conference CASCADE;
DROP TABLE IF EXISTS Researcher CASCADE;
DROP TABLE IF EXISTS University CASCADE;

CREATE TABLE Conference(
	conference_id INT PRIMARY KEY,
	name TEXT
);

CREATE TABLE University(
	university_id INT PRIMARY KEY,
	name TEXT
);

CREATE TABLE Researcher(
	researcher_id INT PRIMARY KEY,
	name TEXT,
	email TEXT UNIQUE,
	university_id INT NOT NULL REFERENCES University
);

CREATE TABLE Participant(
	conference_id INT NOT NULL REFERENCES Conference,
	researcher_id INT NOT NULL REFERENCES Researcher
);

DROP FUNCTION IF EXISTS MockUniversity;
CREATE OR REPLACE FUNCTION MockUniversity(count INT = 1)
RETURNS SETOF University
AS $$
    import random
    unis = [
        'Cambridge University', 'Columbia University', 'Cornell University',
        'Duke University', 'Ecole Polytechnique', 'Harvard University',
        'Imperial College', 'Institute of Technology', 'Johns Hopkins University',
        "Kings College", 'National University', 'National University',
        'Oxford University', 'Princeton University', 'Stanford University',
        'Technological University', 'University College', 'Yale University'
    ]
    cities = [
        'Ahmedabad', 'Alexandria', 'Algiers', 'Ankara', 'Baghdad', 'Baku',
        'Bangkok', 'Berlin', 'Bogota', 'Buenos Aires', 'Busan', 'Cairo',
        'Cape Town', 'Casablanca', 'Chennai', 'Delhi', 'Dhaka', 'Dubai',
        'Durban', 'Guayaquil', 'Hanoi', 'Hyderabad', 'Incheon', 'Istanbul',
        'Izmir', 'Jaipur', 'Jakarta', 'Johannesburg', 'Kabul', 'Kanpur',
        'Karachi', 'Kiev', 'Kolkata', 'Lagos', 'Lahore', 'Lima', 'London',
        'Los Angeles', 'Luanda', 'Madrid', 'Mexico City', 'Moscow', 'Mumbai',
        'New York', 'Quezon City', 'Rome', 'Saint Petersburg', 'Salvador',
        'Santiago', 'Seoul', 'Singapore', 'Surabaya', 'Surat', 'Tehran',
        'Tokyo', 'Yokohama'
    ]
    history = set()
    for i in range(count):
        while True:
            uni = random.choice(unis)
            city = random.choice(cities)
            name = '%s, %s' % (uni, city)
            if name not in history:
                break
        history.add(name)
        yield i+1, name
$$ LANGUAGE plpython3u;

DROP FUNCTION IF EXISTS MockResearcher;
CREATE OR REPLACE FUNCTION MockResearcher(count INT = 1, max_uni INT = 100)
RETURNS SETOF Researcher
AS $$
	import random
	names = [
    	'aaron', 'abigail', 'adam', 'aisha', 'albert', 'alex', 'alexander',
    	'alfie', 'alice', 'amber', 'amelia', 'amelie', 'amy', 'anna', 'annabelle',
    	'archie', 'arthur', 'austin', 'ava', 'beatrice', 'bella', 'benjamin',
	    'bethany', 'blake', 'bobby', 'brooke', 'caleb', 'callum', 'charles',
    	'charlie', 'charlotte', 'chloe', 'connor', 'daisy', 'daniel', 'darcey',
    	'darcie', 'darcy', 'david', 'dexter', 'dylan', 'edward', 'eleanor',
    	'elijah', 'eliza', 'elizabeth', 'ella', 'ellie', 'elliot', 'elliott',
    	'ellis', 'elsie', 'emilia', 'emily', 'emma', 'erin', 'esme', 'ethan',
    	'eva', 'evelyn', 'evie', 'faith', 'felix', 'finlay', 'finley', 'florence',
    	'francesca', 'frankie', 'freddie', 'frederick', 'freya', 'gabriel',
    	'george', 'georgia', 'grace', 'gracie', 'hannah', 'harley', 'harper',
    	'harriet', 'harrison', 'harry', 'harvey', 'heidi', 'henry', 'hollie',
    	'holly', 'hugo', 'ibrahim', 'imogen', 'isaac', 'isabel', 'isabella',
    	'isabelle', 'isla', 'ivy', 'jack', 'jackson', 'jacob', 'jake', 'james',
    	'jamie', 'jasmine', 'jayden', 'jenson', 'jessica', 'joey', 'joseph',
    	'joshua', 'jude', 'julia', 'kai', 'katie', 'kian', 'lacey', 'layla',
    	'leah', 'leo', 'leon', 'lewis', 'lexi', 'liam', 'lilly', 'lily', 'logan',
    	'lola', 'lottie', 'louie', 'louis', 'luca', 'lucas', 'lucy', 'luke',
    	'lydia', 'maisie', 'maria', 'martha', 'maryam', 'mason', 'matilda',
    	'matthew', 'max', 'maya', 'megan', 'mia', 'michael', 'millie', 'mohammad',
    	'mohammed', 'mollie', 'molly', 'muhammad', 'nancy', 'nathan', 'noah',
    	'oliver', 'olivia', 'ollie', 'oscar', 'owen', 'phoebe', 'poppy', 'reuben',
    	'riley', 'robert', 'robyn', 'ronnie', 'rory', 'rose', 'rosie', 'ruby',
    	'ryan', 'samuel', 'sara', 'sarah', 'scarlett', 'sebastian', 'seth',
    	'sienna', 'sofia', 'sonny', 'sophia', 'sophie', 'stanley', 'summer',
    	'teddy', 'thea', 'theo', 'theodore', 'thomas', 'toby', 'tommy', 'tyler',
    	'victoria', 'violet', 'william', 'willow', 'zachary', 'zara', 'zoe'
	]
	surnames = [
    	'adams', 'ali', 'allen', 'anderson', 'andrews', 'armstrong', 'atkinson',
    	'bailey', 'baker', 'barker', 'barnes', 'bell', 'bennett', 'berry',
    	'booth', 'bradley', 'brooks', 'brown', 'butler', 'campbell', 'carr',
    	'carter', 'chambers', 'chapman', 'clark', 'clarke', 'cole', 'collins',
    	'cook', 'cooper', 'cox', 'cunningham', 'davies', 'davis', 'dawson', 'dean',
	    'dixon', 'edwards', 'ellis', 'evans', 'fisher', 'foster', 'fox', 'gardner',
    	'george', 'gibson', 'gill', 'gordon', 'graham', 'grant', 'gray', 'green',
    	'griffiths', 'hall', 'hamilton', 'harper', 'harris', 'harrison', 'hart',
    	'harvey', 'hill', 'holmes', 'hudson', 'hughes', 'hunt', 'hunter',
    	'jackson', 'james', 'jenkins', 'johnson', 'johnston', 'jones', 'kaur',
    	'kelly', 'kennedy', 'khan', 'king', 'knight', 'lane', 'lawrence', 'lawson',
    	'lee', 'lewis', 'lloyd', 'macdonald', 'marshall', 'martin', 'mason',
    	'matthews', 'mcdonald', 'miller', 'mills', 'mitchell', 'moore', 'morgan',
	    'morris', 'murphy', 'murray', 'owen', 'palmer', 'parker', 'patel',
    	'pearce', 'pearson', 'phillips', 'poole', 'powell', 'price', 'reid',
    	'reynolds', 'richards', 'richardson', 'roberts', 'robertson', 'robinson',
    	'rogers', 'rose', 'ross', 'russell', 'ryan', 'saunders', 'scott', 'shaw',
    	'simpson', 'smith', 'spencer', 'stevens', 'stewart', 'stone', 'taylor',
    	'thomas', 'thompson', 'thomson', 'turner', 'walker', 'walsh', 'ward',
    	'watson', 'watts', 'webb', 'wells', 'west', 'white', 'wilkinson',
    	'williams', 'williamson', 'wilson', 'wood', 'wright', 'young'
	]
	letters = 'abcdefghijklmnopqrstuvwxyz'
	servers = [
		'yahoo.com', 'gmail.com', 'yandex.ru', 'mail.ru'
	]
	history = set()
	for i in range(count):
		while True:
			givenname = random.choice(names).title()
			letter = random.choice(letters).upper()
			surname = random.choice(surnames).title()
			server = random.choice(servers).lower()
			year = random.randint(70, 99)
			uni_id = random.randint(1, max_uni)
			fullname = '{} {}'.format(givenname, surname)
			email = '{}{}{}@{}'.format(givenname[0].lower(), surname.lower(),
			                           year, server)
			if fullname not in history and email not in history:
				break
		history.add(fullname)
		history.add(email)
		yield i+1, fullname, email, uni_id
$$ LANGUAGE plpython3u;

DROP FUNCTION IF EXISTS MockConference;
CREATE OR REPLACE FUNCTION MockConference(count INT = 1)
RETURNS SETOF Conference
AS $$
	import random
	names = [
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
	]
	history = set()
	for i in range(count):
		while True:
			name = random.choice(names)
			year = random.randint(1990, 2017)
			fullname = "{}'{}".format(name, str(year)[-2:])
			if fullname not in history:
				break
		history.add(fullname)
		yield i+1, fullname
$$ LANGUAGE plpython3u;

DROP FUNCTION IF EXISTS MockParticipant;
CREATE OR REPLACE FUNCTION MockParticipant(count INT, max_conf INT, max_res INT)
RETURNS SETOF Participant
AS $$
	import random
	history = set()
	for i in range(count):
		while True:
			pair = (random.randint(1, max_conf), random.randint(2, max_res))
			if pair not in history:
				break
		history.add(pair)
		yield pair
$$ LANGUAGE plpython3u;

DROP FUNCTION IF EXISTS MockMax;
CREATE OR REPLACE FUNCTION MockMax(what TEXT) RETURNS INT
AS $$
	maxvals = dict(univ=200, conf=1000, resr=20000, part=100000)
	return maxvals[what]
$$ LANGUAGE plpython3u;

DELETE FROM Participant;
DELETE FROM Conference;
DELETE FROM Researcher;
DELETE FROM University;

INSERT INTO University  (SELECT * FROM MockUniversity(MockMax('univ')));
INSERT INTO Researcher  (SELECT * FROM MockResearcher(MockMax('resr'), MockMax('univ')));
INSERT INTO Conference  (SELECT * FROM MockConference(MockMax('conf')));
INSERT INTO Participant (SELECT * FROM MockParticipant(MockMax('part'), MockMax('conf'), MockMax('resr')));

SELECT R.researcher_id AS id, R.name AS fullname, U.name AS uni, R.email
FROM Researcher R JOIN University U ON R.university_id = U.university_id;

SELECT R.name AS name, U.name as uni, C.name as conf
FROM Participant P
JOIN Conference C ON P.conference_id = C.conference_id
JOIN Researcher R ON P.researcher_id = R.researcher_id
JOIN University U ON R.university_id = U.university_id;

SELECT COUNT(P.researcher_id) as count, C.name as conf, U.name as uni
FROM Participant P
JOIN Conference C ON P.conference_id = C.conference_id
JOIN Researcher R ON P.researcher_id = R.researcher_id
JOIN University U ON R.university_id = U.university_id
GROUP BY C.name, U.name
HAVING COUNT(P.researcher_id) > 1
ORDER BY count DESC, conf ASC, UNI asc;

EXPLAIN ANALYZE
SELECT * FROM Participant P
JOIN Conference C ON P.conference_id = C.conference_id
JOIN Researcher R ON P.researcher_id = R.researcher_id
JOIN University U ON R.university_id = U.university_id;

SELECT ROUND(AVG(cnt)) AS avg_confs_per_reschr FROM (
  SELECT COUNT(conference_id) as cnt from Participant GROUP BY researcher_id
) Cnts;

SELECT ROUND(AVG(cnt)) AS avg_reschrs_per_conf FROM (
  SELECT COUNT(researcher_id) as cnt from Participant GROUP BY conference_id
) Cnts;

SELECT pg_total_relation_size('Researcher');
