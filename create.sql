/* =========================================================
   NFL (Ultra-Simple 3NF) — DDL + DML + DQL + Wipe
   Target: SQL Server 2016+
   Objects: nfl.conference, nfl.division, nfl.team, nfl.player
   ========================================================= */

/* ============================================================
   0) Clean wipe / reset
   ============================================================ */
IF OBJECT_ID('nfl.player', 'U')     IS NOT NULL DROP TABLE nfl.player;
IF OBJECT_ID('nfl.team', 'U')       IS NOT NULL DROP TABLE nfl.team;
IF OBJECT_ID('nfl.division', 'U')   IS NOT NULL DROP TABLE nfl.division;
IF OBJECT_ID('nfl.conference', 'U') IS NOT NULL DROP TABLE nfl.conference;

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'nfl')
BEGIN
  -- schema will be dropped automatically when empty; keep it for reuse
  -- (comment next line to force drop)
  -- EXEC('DROP SCHEMA nfl');
END
GO

/* ============================================================
   1) Create schema
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'nfl')
    EXEC('CREATE SCHEMA nfl');
GO

/* ============================================================
   2) DDL — Tables (3NF)
   ============================================================ */

-- 2.1 Conference
CREATE TABLE nfl.conference
(
    conference_id INT IDENTITY(1,1) PRIMARY KEY,
    name          VARCHAR(50)  NOT NULL UNIQUE,  -- 'American Football Conference'
    abbr          VARCHAR(10)  NOT NULL UNIQUE   -- 'AFC', 'NFC'
);

-- 2.2 Division (depends on Conference)
CREATE TABLE nfl.division
(
    division_id   INT IDENTITY(1,1) PRIMARY KEY,
    conference_id INT         NOT NULL
        REFERENCES nfl.conference(conference_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    name          VARCHAR(50) NOT NULL,          -- 'East','North','South','West'
    CONSTRAINT UQ_division_conf_name UNIQUE (conference_id, name)
);

-- 2.3 Team (depends on Division)
CREATE TABLE nfl.team
(
    team_id      INT IDENTITY(1,1) PRIMARY KEY,
    division_id  INT          NOT NULL
        REFERENCES nfl.division(division_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    abbr         VARCHAR(5)   NOT NULL UNIQUE,   -- BUF, KC, LAC, WAS, etc.
    city         VARCHAR(80)  NOT NULL,          -- 'Buffalo'
    nickname     VARCHAR(80)  NOT NULL,          -- 'Bills'
    full_name    AS (CONCAT(city, ' ', nickname)) PERSISTED, -- computed
    CONSTRAINT UQ_team_city_nick UNIQUE (city, nickname)
);

-- 2.4 Player (depends on Team)
CREATE TABLE nfl.player
(
    player_id     INT IDENTITY(1,1) PRIMARY KEY,
    team_id       INT          NOT NULL
        REFERENCES nfl.team(team_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,   -- if a team is removed, players go too
    first_name    VARCHAR(80) NOT NULL,
    last_name     VARCHAR(80) NOT NULL,
    position      VARCHAR(10) NOT NULL,
    jersey_number TINYINT     NULL,              -- nullable (roster churn)
    -- keep it simple: constrain to common positions (expand as needed)
    CONSTRAINT CK_player_position
      CHECK (position IN ('QB','RB','WR','TE','FB','LT','LG','C','RG','RT',
                          'OL','DL','EDGE','DE','DT','LB','ILB','OLB','CB',
                          'S','FS','SS','DB','K','P','LS'))
);
GO

/* ============================================================
   3) DML — Seed (Conferences, Divisions, Teams)
   ============================================================ */

-- 3.1 Conferences
INSERT INTO nfl.conference (name, abbr)
VALUES
  ('American Football Conference', 'AFC'),
  ('National Football Conference', 'NFC');

-- 3.2 Divisions
INSERT INTO nfl.division (conference_id, name)
SELECT c.conference_id, d.name
FROM (VALUES ('AFC','East'),('AFC','North'),('AFC','South'),('AFC','West'),
             ('NFC','East'),('NFC','North'),('NFC','South'),('NFC','West')) d(conf_abbr, name)
JOIN nfl.conference c ON c.abbr = d.conf_abbr;

-- 3.3 Teams (all 32) — works in SQL Server


;WITH myData AS
(
   SELECT *
    FROM (
        VALUES
            ('AFC','East','BUF','Buffalo','Bills'),
            ('AFC','East','MIA','Miami','Dolphins'),
            ('AFC','East','NE','New England','Patriots'),
            ('AFC','East','NYJ','New York','Jets'),
            -- AFC North
            ('AFC','North','BAL','Baltimore','Ravens'),
            ('AFC','North','CIN','Cincinnati','Bengals'),
            ('AFC','North','CLE','Cleveland','Browns'),
            ('AFC','North','PIT','Pittsburgh','Steelers'),
            -- AFC South
            ('AFC','South','HOU','Houston','Texans'),
            ('AFC','South','IND','Indianapolis','Colts'),
            ('AFC','South','JAX','Jacksonville','Jaguars'),
            ('AFC','South','TEN','Tennessee','Titans'),
            -- AFC West
            ('AFC','West','DEN','Denver','Broncos'),
            ('AFC','West','KC','Kansas City','Chiefs'),
            ('AFC','West','LV','Las Vegas','Raiders'),
            ('AFC','West','LAC','Los Angeles','Chargers'),
            -- NFC East
            ('NFC','East','DAL','Dallas','Cowboys'),
            ('NFC','East','NYG','New York','Giants'),
            ('NFC','East','PHI','Philadelphia','Eagles'),
            ('NFC','East','WAS','Washington','Commanders'),
            -- NFC North
            ('NFC','North','CHI','Chicago','Bears'),
            ('NFC','North','DET','Detroit','Lions'),
            ('NFC','North','GB','Green Bay','Packers'),
            ('NFC','North','MIN','Minneapolis','Vikings'),
            -- NFC South
            ('NFC','South','TB','Tampa Bay','Buccaneers'),
            ('NFC','South','ATL','Atlanta','Falcons'),
            ('NFC','South','CAR','Carolina','Panthers'),
            ('NFC','South','NO','New Orleans','Saints'),
            -- NFC West
            ('NFC','West','ARI','Arizona','Cardinals'),
            ('NFC','West','LAR','Los Angeles','Rams'),
            ('NFC','West','SF','San Francisco','49ers'),
            ('NFC','West','SEA','Seattle','Seahawks')
        ) AS s(conf_abbr, div_name, abbr, city, nickname) 
)

INSERT INTO nfl.team (division_id, abbr, city, nickname)
SELECT d.division_id, m.abbr, m.city, m.nickname
FROM myData m 
JOIN nfl.conference c   ON c.abbr = m.conf_abbr
JOIN nfl.division   d   ON d.conference_id = c.conference_id AND d.name = m.div_name;



-- 3.4 Sample players (1 per team so you can test joins)
-- (Full 2025 roster load is provided later via CSV bulk insert)
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Josh','Allen','QB',17           FROM nfl.team WHERE abbr='BUF';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Tua','Tagovailoa','QB',1        FROM nfl.team WHERE abbr='MIA';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Drake','Maye','QB',10           FROM nfl.team WHERE abbr='NE';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Aaron','Rodgers','QB',8         FROM nfl.team WHERE abbr='NYJ';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Lamar','Jackson','QB',8         FROM nfl.team WHERE abbr='BAL';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Joe','Burrow','QB',9            FROM nfl.team WHERE abbr='CIN';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Myles','Garrett','EDGE',95      FROM nfl.team WHERE abbr='CLE';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'T.J.','Watt','EDGE',90          FROM nfl.team WHERE abbr='PIT';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'C.J.','Stroud','QB',7           FROM nfl.team WHERE abbr='HOU';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Anthony','Richardson','QB',5    FROM nfl.team WHERE abbr='IND';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Trevor','Lawrence','QB',16      FROM nfl.team WHERE abbr='JAX';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Will','Levis','QB',8            FROM nfl.team WHERE abbr='TEN';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Patrick','Surtain II','CB',2    FROM nfl.team WHERE abbr='DEN';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Patrick','Mahomes','QB',15      FROM nfl.team WHERE abbr='KC';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Davante','Adams','WR',17        FROM nfl.team WHERE abbr='LV';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Justin','Herbert','QB',10       FROM nfl.team WHERE abbr='LAC';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Dak','Prescott','QB',4          FROM nfl.team WHERE abbr='DAL';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Dexter','Lawrence','DT',97      FROM nfl.team WHERE abbr='NYG';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Jalen','Hurts','QB',1           FROM nfl.team WHERE abbr='PHI';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Jayden','Daniels','QB',5        FROM nfl.team WHERE abbr='WAS';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Caleb','Williams','QB',13       FROM nfl.team WHERE abbr='CHI';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Jared','Goff','QB',16           FROM nfl.team WHERE abbr='DET';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Jordan','Love','QB',10          FROM nfl.team WHERE abbr='GB';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Justin','Jefferson','WR',18     FROM nfl.team WHERE abbr='MIN';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Mike','Evans','WR',13           FROM nfl.team WHERE abbr='TB';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Bijan','Robinson','RB',7        FROM nfl.team WHERE abbr='ATL';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Bryce','Young','QB',9           FROM nfl.team WHERE abbr='CAR';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Chris','Olave','WR',12          FROM nfl.team WHERE abbr='NO';

INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Kyler','Murray','QB',1          FROM nfl.team WHERE abbr='ARI';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Puka','Nacua','WR',17           FROM nfl.team WHERE abbr='LAR';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'Brock','Purdy','QB',13          FROM nfl.team WHERE abbr='SF';
INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
SELECT team_id, 'DK','Metcalf','WR',14           FROM nfl.team WHERE abbr='SEA';
GO

/* ============================================================
   4) DQL — Handy sample queries
   ============================================================ */

-- 4.1 Teams by conference/division
SELECT c.abbr AS conference, d.name AS division, t.abbr AS team_abbr, t.full_name
FROM nfl.team t
JOIN nfl.division d   ON d.division_id = t.division_id
JOIN nfl.conference c ON c.conference_id = d.conference_id
ORDER BY c.abbr, d.name, t.abbr;

-- 4.2 Player count per team
SELECT t.abbr AS team, COUNT(*) AS players
FROM nfl.player p
JOIN nfl.team t ON t.team_id = p.team_id
GROUP BY t.abbr
ORDER BY t.abbr;

-- 4.3 All QBs with their divisions
SELECT p.first_name, p.last_name, p.position, t.abbr AS team, d.name AS division, c.abbr AS conference
FROM nfl.player p
JOIN nfl.team t       ON t.team_id = p.team_id
JOIN nfl.division d   ON d.division_id = t.division_id
JOIN nfl.conference c ON c.conference_id = d.conference_id
WHERE p.position = 'QB'
ORDER BY c.abbr, d.name;

-- 4.4 Find players by last name (example: Allen)
SELECT p.*, t.abbr AS team
FROM nfl.player p
JOIN nfl.team t ON t.team_id = p.team_id
WHERE p.last_name = 'Allen';

-- 4.5 Teams in each division
SELECT c.abbr AS conference, d.name AS division, STRING_AGG(t.abbr, ', ') WITHIN GROUP (ORDER BY t.abbr) AS teams
FROM nfl.team t
JOIN nfl.division d ON d.division_id = t.division_id
JOIN nfl.conference c ON c.conference_id = d.conference_id
GROUP BY c.abbr, d.name
ORDER BY c.abbr, d.name;

/* -------------------------
   5) Optional: Bulk-load ALL 2025 players from CSV
   (Run this after DDL/DML above has created teams)
   -------------------------

   1) Prepare UTF-8 CSV with header like:
      first_name,last_name,position,jersey_number,team_abbr
      Josh,Allen,QB,17,BUF
      Tyreek,Hill,WR,10,MIA
      ... (one row per player on 2025 rosters)

   2) Ensure SQL Server service account can read the path.
   3) Update the file path below and run this section.
*/

-- Example staging table (temp) + bulk insert + merge into nfl.player
CREATE TABLE #player_stage
(
    first_name    VARCHAR(80) NOT NULL,
    last_name     VARCHAR(80) NOT NULL,
    position      VARCHAR(10) NOT NULL,
    jersey_number TINYINT     NULL,
    team_abbr     VARCHAR(5)  NOT NULL
);

-- CHANGE THE PATH BELOW:
-- BULK INSERT #player_stage
-- FROM 'C:\data\nfl_players_2025.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ',',
--     ROWTERMINATOR   = '0x0a',
--     TABLOCK,
--     CODEPAGE = '65001'  -- UTF-8
-- );

-- Insert into target (skip duplicates if you re-run: simple NOT EXISTS guard)
-- INSERT INTO nfl.player (team_id, first_name, last_name, position, jersey_number)
-- SELECT t.team_id, s.first_name, s.last_name, s.position, s.jersey_number
-- FROM #player_stage s
-- JOIN nfl.team t ON t.abbr = s.team_abbr
-- WHERE NOT EXISTS (
--   SELECT 1 FROM nfl.player p
--   WHERE p.team_id = t.team_id
--     AND p.first_name = s.first_name
--     AND p.last_name  = s.last_name
--     AND p.position   = s.position
-- );

-- DROP TABLE #player_stage;
GO

/* ============================================================
   6) Quick wipe snippet (copy/paste to destroy)
   ============================================================ */
-- DROP TABLE IF EXISTS nfl.player;
-- DROP TABLE IF EXISTS nfl.team;
-- DROP TABLE IF EXISTS nfl.division;
-- DROP TABLE IF EXISTS nfl.conference;
-- -- optional: drop the schema itself
-- -- IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'nfl') EXEC('DROP SCHEMA nfl');

/*

CREATE TABLE dbo.test
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    name          VARCHAR(50)  NOT NULL UNIQUE
);

;WITH myData1 AS
(
   SELECT *
    FROM (
        VALUES
        ('Frank')
   ) AS T(name) 
)

INSERT INTO dbo.test(name)
SELECT *
FROM myData1
*/
