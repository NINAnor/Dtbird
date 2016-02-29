DROP TABLE IF EXISTS dato;
DROP TABLE IF EXISTS time_int;
DROP TABLE IF EXISTS data;
DROP TABLE IF EXISTS tempo;
DROP TABLE IF EXISTS temp_42;
DROP TABLE IF EXISTS temp_1;
DROP TABLE IF EXISTS joined;

CREATE TEMP TABLE dato as

SELECT b.date_on
FROM "oyvind.hamre".dtbird_uptime a, "oyvind.hamre".dtbird_uptime b
WHERE a.turbine='1' AND b.turbine='42' AND a.date_on=b.date_on;

--SELECT* FROM dato;

CREATE TEMP TABLE time_int AS

SELECT a.date_on,max(a.switch_on),min(a.switch_off) FROM "oyvind.hamre".dtbird_uptime a,dato 
WHERE a.date_on=dato.date_on GROUP BY a.date_on ORDER BY a.date_on ASC;

--SELECT* FROM time_int;

CREATE TEMP TABLE data AS

SELECT *, 
	CASE WHEN species_group='Eagle sp. ' THEN 'eagle' WHEN species_group='White-tailed eagle' THEN 'eagle' WHEN species_group='Golden eagle' THEN 'eagle' WHEN species_group='False Positive (FP)' THEN 'fp' ELSE 'bird' END AS all_birds
FROM "oyvind.hamre".dtbird;

--SELECT* FROM data;

CREATE TEMP TABLE tempo AS

SELECT extract(isoyear from date_and_hour) as iyear, extract(week from date_and_hour) as uke, data.turbine, all_birds,
 species_group, sum(no_of_birds) as no_birds, count(species_group) as observations, count(all_birds) AS bird_obs

FROM time_int left join data on (date_on = date(date_and_hour))

WHERE date_and_hour > '2013.08.14'

GROUP BY iyear, uke, data.turbine, species_group, all_birds
ORDER BY iyear, uke;

--SELECT* FROM tempo;


CREATE TEMP TABLE temp_42 AS

SELECT * FROM crosstab(
	'SELECT uke, iyear,  all_birds, bird_obs
	 FROM tempo
	 WHERE turbine = 42
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
	'SELECT uke, iyear,  all_birds, bird_obs
	 FROM tempo
	 WHERE turbine = 1
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

--SELECT * FROM temp_42;
--SELECT * FROM temp_1;	

-- create joined does not work??
CREATE TEMP TABLE joined AS

SELECT * FROM temp_42
LEFT OUTER JOIN temp_1
ON temp_42.uke = temp_1.uke AND temp_42.iyear = temp_1.iyear
ORDER BY temp_1.iyear, temp_1.uke;