-- CREATE EXTENSION tablefunc;

DROP TABLE IF EXISTS time_int;
DROP TABLE IF EXISTS tempo;
DROP TABLE IF EXISTS temp_42;
DROP TABLE IF EXISTS temp_1;


CREATE TEMP TABLE time_int AS
SELECT date_on,max(switch_on),min(switch_off) FROM "oyvind.hamre".dtbird_uptime WHERE turbine<>21 AND date_on>'2013.08.09' GROUP BY date_on ORDER BY date_on ASC;


CREATE TEMP TABLE tempo AS
SELECT extract(isoyear from date_and_hour) as iyear, extract(week from date_and_hour) as uke, bird.turbine,
 species_group, sum(no_of_birds) as No_birds, count(no_of_birds) as no_bird_obs

FROM time_int left join "oyvind.hamre".dtbird bird on (date_on = date(date_and_hour))

WHERE date_and_hour > '2013.08.14'

GROUP BY iyear, uke, bird.turbine, species_group
ORDER BY iyear, uke;

CREATE TEMP TABLE temp_42 AS

SELECT * FROM crosstab(
	'SELECT uke, iyear,  species_group, no_birds
	 FROM tempo
	 WHERE turbine = 42
	 ORDER by 2, 1',
	 $$VALUES ('False Positive (FP)'), ('Eagle sp. '), ('Golden eagle'), ('White-tailed eagle')$$
	 )
AS result (
	"uke" double precision,
	"iyear" double precision,
	
	"false_positive_42" text,
	"eagle_42" text,
	"golden eagle_42" text,
	"wt_eagle_42" text
	);

CREATE TEMP TABLE temp_1 AS

SELECT * FROM crosstab(
	'SELECT uke, iyear,  species_group, no_birds
	 FROM tempo
	 WHERE turbine = 1
	 ORDER by 2, 1',
	 $$VALUES ('False Positive (FP)'), ('Eagle sp. '), ('Golden eagle'), ('White-tailed eagle')$$
	 )
AS result (
	"uke" double precision,
	"iyear" double precision,
	
	"false_positive_1" text,
	"eagle_1" text,
	"golden eagle_1" text,
	"wt_eagle_1" text
	);

/*	
SELECT * FROM tempo;
SELECT * FROM temp_42;
SELECT * FROM temp_1;	 
*/

SELECT * FROM temp_42
LEFT OUTER JOIN temp_1
ON temp_42.uke = temp_1.uke AND temp_42.iyear = temp_1.iyear
ORDER BY temp_1.iyear, temp_1.uke;
