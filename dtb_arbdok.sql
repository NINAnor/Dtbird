DROP TABLE IF EXISTS dato;
DROP TABLE IF EXISTS time_int;
DROP TABLE IF EXISTS tempo;
DROP TABLE IF EXISTS temp_42;
DROP TABLE IF EXISTS temp_1;

CREATE TEMP TABLE dato as

SELECT b.date_on,b.date_off
FROM "oyvind.hamre".dtbird_uptime a, "oyvind.hamre".dtbird_uptime b
WHERE a.turbine='1' AND b.turbine='42' AND a.date_on=b.date_on AND a.date_off=b.date_off;

--SELECT* FROM dato;

CREATE TEMP TABLE time_int AS

SELECT a.date_on,max(a.switch_on),min(a.switch_off) FROM "oyvind.hamre".dtbird_uptime a,dato 
WHERE a.date_on=dato.date_on GROUP BY a.date_on ORDER BY a.date_on ASC;

--SELECT* FROM time_int;

CREATE TEMP TABLE tempo AS
SELECT extract(isoyear from date_and_hour) as iyear, extract(week from date_and_hour) as uke, bird.turbine,
 species_group, sum(no_of_birds) as no_birds, count(species_group) as observations

FROM time_int left join "oyvind.hamre".dtbird bird on (date_on = date(date_and_hour))

WHERE date_and_hour > '2013.08.14'

GROUP BY iyear, uke, bird.turbine, species_group
ORDER BY iyear, uke;

--SELECT* FROM tempo;

CREATE TEMP TABLE temp_42 AS

SELECT * FROM crosstab(
	'SELECT uke, iyear,  species_group, observations
	 FROM tempo
	 WHERE turbine = 42
	 ORDER by 2, 1',
	 $$VALUES ('False Positive (FP)'), ('Eagle sp. '), ('Golden eagle'), ('White-tailed eagle'),
	 ('Eagle sp. ' AND 'Golden eagle' AND 'White-tailed eagle')$$
	 )
AS result (
	"uke" double precision,
	"iyear" double precision,
	
	"fp_42" text,
	"eagle_42" text,
	"golden eagle_42" text,
	"wt_eagle_42" text,
	"test" text
	);

SELECT* FROM temp_42;