/*To quarry a given timeframe that is umique each day on a different table.*/

DROP TABLE IF EXISTS dato;
DROP TABLE IF EXISTS time_int;
DROP TABLE IF EXISTS time_int_week;
DROP TABLE IF EXISTS dated;
DROP TABLE IF EXISTS tempo;
DROP TABLE IF EXISTS temp_42;
DROP TABLE IF EXISTS temp_1;
DROP TABLE IF EXISTS joined;

/* Selecting the days to use in timeframe*/
CREATE TEMP TABLE dato as

SELECT b.date_on
FROM "oyvind.hamre".dtbird_uptime a, "oyvind.hamre".dtbird_uptime b
WHERE a.turbine='1' AND b.turbine='42' AND a.date_on=b.date_on;

--SELECT* FROM dato;

/* Selecting the max timeframe each day when bouth systems was running */

CREATE TEMP TABLE time_int AS

SELECT a.date_on,max(a.switch_on),min(a.switch_off)
FROM "oyvind.hamre".dtbird_uptime a,dato 
WHERE a.date_on=dato.date_on GROUP BY a.date_on ORDER BY a.date_on ASC;

--SELECT* FROM time_int;
/* Extracting week and isoyear to make sorting of data in later table "joined" */

CREATE TEMP TABLE time_int_week AS

SELECT a.date_on, extract(isoyear from a.date_on) as iyear, extract(week from a.date_on) as uke
FROM "oyvind.hamre".dtbird_uptime a,dato 
WHERE a.date_on=dato.date_on AND a.date_on > '2013.08.14'
GROUP BY a.date_on ORDER BY a.date_on ASC;

--SELECT * FROM time_int_week;

/* Creating new grouping of data from original data */
CREATE TEMP TABLE dated AS

SELECT *, 
	CASE WHEN species_group='Eagle sp. ' THEN 'eagle' WHEN species_group='White-tailed eagle' THEN 'eagle' WHEN species_group='Golden eagle' THEN 'eagle' WHEN species_group='False Positive (FP)' THEN 'fp' ELSE 'bird' END AS all_birds
FROM "oyvind.hamre".dtbird;

--SELECT* FROM dated;

CREATE TEMP TABLE tempo AS

SELECT extract(isoyear from date_and_hour) as iyear, extract(week from date_and_hour) as uke, dated.turbine, all_birds,
 species_group, sum(no_of_birds) as no_birds, count(species_group) as observations, count(all_birds) AS bird_obs

FROM time_int left join dated on (date_on = date(date_and_hour))

WHERE date_and_hour > '2013.08.14'

GROUP BY iyear, uke, dated.turbine, species_group, all_birds
ORDER BY iyear, uke;

--SELECT* FROM tempo;


CREATE TEMP TABLE temp_42 AS

SELECT * FROM crosstab(
	'SELECT uke, iyear,  all_birds, sum(bird_obs)
	 FROM tempo
	 WHERE turbine = 42
	 GROUP BY uke, iyear, all_birds
	 ORDER by 2, 1',
	 $$VALUES ('eagle'), ('bird'), ('fp')$$
	 )
AS result (
	"uke" double precision,
	"iyear" double precision,
	
	"eagle_42" text,
	"bird_42" text,
	"fp_42" text
	);

--SELECT* FROM temp_42;

CREATE TEMP TABLE temp_1 AS

SELECT * FROM crosstab(
	'SELECT uke, iyear,  all_birds, sum(bird_obs)
	 FROM tempo
	 WHERE turbine = 1
	 GROUP BY uke, iyear, all_birds
	 ORDER by 2, 1',
	 $$VALUES ('eagle'), ('bird'), ('fp')$$
	 )
AS result (
	"uke" double precision,
	"iyear" double precision,
	
	"eagle_1" text,
	"bird_1" text,
	"fp_1" text
	);

--SELECT * FROM temp_42;
--SELECT * FROM temp_1;	


CREATE TEMP TABLE joined AS


SELECT DISTINCT a.uke, a.iyear, b.eagle_42, b.bird_42, b.fp_42, c.eagle_1, c.bird_1, c.fp_1
FROM time_int_week AS a LEFT OUTER JOIN temp_42 AS b ON (a.uke= b.uke AND a.iyear=b.iyear) LEFT OUTER JOIN temp_1 AS c ON (a.uke=c.uke AND a.iyear=c.iyear)
ORDER BY a.iyear, a.uke;

SELECT * FROM joined;
/*
CREATE TABLE "oyvind.hamre".dtbird_t1_t42 AS
SELECT * FROM joined;

-- Giving a value to the weeks that has no vallue--

UPDATE "oyvind.hamre".dtbird_t1_t42
SET eagle_42='0'
WHERE eagle_42 IS NULL;

UPDATE "oyvind.hamre".dtbird_t1_t42
SET eagle_1='0'
WHERE eagle_1 IS NULL;

UPDATE "oyvind.hamre".dtbird_t1_t42
SET bird_42='0'
WHERE bird_42 IS NULL;

UPDATE "oyvind.hamre".dtbird_t1_t42
SET bird_1='0'
WHERE bird_1 IS NULL;

UPDATE "oyvind.hamre".dtbird_t1_t42
SET fp_1='0'
WHERE fp_1 IS NULL;

UPDATE "oyvind.hamre".dtbird_t1_t42
SET fp_42='0'
WHERE fp_42 IS NULL;
*/