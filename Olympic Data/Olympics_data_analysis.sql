/*

120 YEARS OF OLYMPICS DATA FOR ANALYSIS

*/

Select *
FROM Olympics..OLYMPICS_HISTORY;

--Q.1) HOW MANY OLYMPICS GAMES HAVE BEEN HELD?

Select COUNT(DISTINCT(Games)) as total_olympic_games
FROM Olympics..OLYMPICS_HISTORY;



--Q.2) LIST DOWN ALL OLYMPICS GAMES HELD SO FAR.

Select DISTINCT Year, Season, City
FROM Olympics..OLYMPICS_HISTORY
ORDER BY Year;



--Q.3) MENTION THE TOTAL NO OF NATIONS WHO PARTICIPATED IN EACH OLYMPICS GAME?

Select oh.Games, COUNT(DISTINCT r.region) as total_countries
FROM Olympics..OLYMPICS_HISTORY oh
JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
ON oh.NOC=r.NOC
GROUP BY oh.Games
ORDER BY oh.Games;



--Q.4) WHICH YEAR SAW THE HIGHEST AND LOWEST NO OF COUNTRIES PARTICIPATING IN OLYMPICS?

WITH cte as (
Select oh.Games, COUNT(DISTINCT r.region) as total_countries
FROM Olympics..OLYMPICS_HISTORY oh
JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
ON oh.NOC=r.NOC
GROUP BY oh.Games)
SELECT DISTINCT
	CONCAT(FIRST_VALUE(games) OVER (ORDER BY total_countries),' - ',FIRST_VALUE(total_countries) OVER (ORDER BY total_countries)) as lowest_no_of_countries,
	CONCAT(FIRST_VALUE(games) OVER (ORDER BY total_countries DESC),' - ',FIRST_VALUE(total_countries) OVER (ORDER BY total_countries DESC)) as highest_no_of_countries
FROM cte;



--Q.5) WHICH NATION HAS PARTICIPATED IN ALL OF THE OLYMPIC GAMES?

WITH cte as (
	SELECT r.region as country, 
			COUNT(DISTINCT games) as total_participated_games
	FROM Olympics..OLYMPICS_HISTORY oh
	JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
	ON oh.NOC=r.NOC
	GROUP BY r.region
)
SELECT * FROM cte WHERE total_participated_games=51;



--Q.6) IDENTIFY THE SPORT WHICH WAS PLAYED IN ALL SUMMER OLYMPICS.

SELECT COUNT(DISTINCT Games) as games
FROM Olympics..OLYMPICS_HISTORY
WHERE season = 'Summer'; -- Identifying how many games are played in Summer

WITH summer_sports as (
	SELECT sport, COUNT(DISTINCT games) as no_of_games
	FROM Olympics..OLYMPICS_HISTORY
	WHERE season = 'Summer'
	GROUP BY sport
)
SELECT * FROM summer_sports
WHERE no_of_games=29
ORDER BY no_of_games;



--Q.7) WHICH SPORTS WERE JUST PLAYED ONLY ONCE IN THE OLYMPICS?

WITH games_with_sports as (
	SELECT DISTINCT games, sport
	FROM Olympics..OLYMPICS_HISTORY
	),
	games_count as (
	SELECT sport, COUNT(games) as total_games 
	FROM games_with_sports
	GROUP BY sport
	)
SELECT games_count.*,games_with_sports.games
FROM games_count
JOIN games_with_sports
ON games_count.sport=games_with_sports.sport
WHERE total_games=1
ORDER BY sport;



--Q.8) FETCH THE TOTAL NO OF SPORTS PLAYED IN EACH OLYMPIC GAMES.

SELECT DISTINCT games, COUNT(DISTINCT sport) as total_no_of_sport
FROM Olympics..OLYMPICS_HISTORY
GROUP BY games
ORDER BY total_no_of_sport DESC;



--Q.9) FETCH DETAILS OF THE OLDEST ATHLETES TO WIN A GOLD MEDAL.

WITH athlete_details as (
		SELECT name, sex, CAST(CASE WHEN age is null THEN '0' ELSE age END AS INT) as age, team, games, city, sport, event, medal
		FROM Olympics..OLYMPICS_HISTORY
		WHERE medal='Gold'),
	age_rnk as(
		SELECT athlete_details.*, RANK() OVER (ORDER BY age DESC) as rnk
		FROM athlete_details)
SELECT * FROM age_rnk WHERE rnk=1;



--Q.10) FIND THE RATIO OF MALE AND FEMALE ATHLETES PARTICIPATED IN ALL OLYMPIC GAMES.

WITH t1 as (
	SELECT sex, COUNT(sex) as cnt
	FROM Olympics..OLYMPICS_HISTORY 
	GROUP BY sex),
	t2 as (
	SELECT *, row_number() over(order by cnt) as rn from t1),
	min_cnt as (SELECT cnt FROM t2 WHERE rn=1),
	max_cnt as (SELECT cnt FROM t2 WHERE rn=2)
SELECT CONCAT('1 : ',max_cnt.cnt/min_cnt.cnt) as ratio FROM min_cnt, max_cnt;



--Q.11) FETCH THE TOP 5 ATHLETES WHO HAVE WON THE MOST GOLD MEDALS.

WITH total_medals as (
	SELECT oh.name, r.region as team, COUNT(oh.medal) as total_gold_medals
	FROM Olympics..OLYMPICS_HISTORY oh
	JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
	ON oh.NOC=r.NOC
	WHERE medal='Gold'
	GROUP BY oh.name, r.region),
	athlete_rnk as (
	SELECT *, DENSE_RANK() OVER (ORDER BY total_gold_medals DESC) as dense_rnk
	FROM total_medals)
SELECT name, team, total_gold_medals
FROM athlete_rnk
WHERE dense_rnk <=5;



--Q.12) FETCH THE TOP 5 ATHLETES WHO HAVE WON THE MOST MEDALS (GOLD/SILVER/BRONZE).

WITH total_medals as (
	SELECT oh.name, r.region as team, COUNT(oh.medal) as no_of_medals
	FROM Olympics..OLYMPICS_HISTORY oh
	JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
	ON oh.NOC=r.NOC
	WHERE medal in ('Gold','Silver','Bronze')
	GROUP BY oh.name, r.region),
	athlete_rnk as (
	SELECT *, DENSE_RANK() OVER (ORDER BY no_of_medals DESC) as dense_rnk
	FROM total_medals)
SELECT name, team, no_of_medals
FROM athlete_rnk
WHERE dense_rnk <=5;



--Q.13) FETCH THE TOP 5 MOST SUCCESSFUL COUNTRIES IN OLYMPICS. SUCCESS IS DEFINED BY NO OF MEDALS WON.

WITH temp as (
	SELECT r.region, COUNT(oh.medal) as total_medals
	FROM Olympics..OLYMPICS_HISTORY oh
	JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
	ON oh.NOC=r.NOC
	WHERE medal in ('Gold','Silver','Bronze')
	GROUP BY r.region),
	country_rnk as (
	SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) as dense_rnk
	FROM temp)
SELECT region, total_medals
FROM country_rnk
WHERE dense_rnk <=5;



--Q.14) LIST DOWN TOTAL GOLD, SILVER AND BROZE MEDALS WON BY EACH COUNTRY.

WITH total_gold as (
		SELECT r.region, COUNT(oh.medal) as gold_medals -- Getting count for gold medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Gold'
		GROUP BY r.region),
	total_silver as (
		SELECT r.region, COUNT(oh.medal) as silver_medals -- Getting count for silver medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Silver'
		GROUP BY r.region),
	total_bronze as (
		SELECT r.region, COUNT(oh.medal) as bronze_medals -- Getting count for bronze medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Bronze'
		GROUP BY r.region)
SELECT g.region, 
	g.gold_medals as gold, 
	s.silver_medals as silver, 
	b.bronze_medals as bronze
FROM total_gold	g						-- Joining the temp tables for getting the values
LEFT JOIN total_silver s ON g.region=s.region
LEFT JOIN total_bronze b ON g.region=b.region
ORDER BY gold_medals DESC;



--Q.15) LIST DOWN TOTAL GOLD, SILVER AND BROZE MEDALS WON BY EACH COUNTRY CORRESPONDING TO EACH OLYMPIC GAMES.

WITH total_gold as (
		SELECT oh.games, r.region, COUNT(oh.medal) as gold_medals -- Getting count for gold medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Gold'
		GROUP BY oh.games, r.region),
	total_silver as (
		SELECT oh.games, r.region, COUNT(oh.medal) as silver_medals -- Getting count for silver medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Silver'
		GROUP BY oh.games, r.region),
	total_bronze as (
		SELECT oh.games, r.region, COUNT(oh.medal) as bronze_medals -- Getting count for bronze medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Bronze'
		GROUP BY oh.games, r.region)
SELECT g.games, g.region, 
	COALESCE(g.gold_medals,0) as gold,
	COALESCE(s.silver_medals,0) as silver, 
	COALESCE(b.bronze_medals,0) as bronze
FROM total_gold	g						-- Joining the temp tables for getting the values
LEFT JOIN total_silver s ON g.region=s.region and g.games=s.games
LEFT JOIN total_bronze b ON g.region=b.region and g.games=b.games
ORDER BY games;



--Q.16) IDENTIFY WHICH COUNTRY WON THE MOST GOLD, MOST SILVER AND MOST BRONZE MEDALS IN EACH OLYMPIC GAMES.

WITH total_gold as (
		SELECT oh.games, r.region, COUNT(oh.medal) as gold_medals -- Getting count for gold medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Gold'
		GROUP BY r.region, oh.games),
	
	total_silver as (
		SELECT oh.games, r.region, COUNT(oh.medal) as silver_medals -- Getting count for silver medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Silver'
		GROUP BY r.region, oh.games),
	
	total_bronze as (
		SELECT oh.games, r.region, COUNT(oh.medal) as bronze_medals -- Getting count for bronze medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Bronze'
		GROUP BY r.region, oh.games),
	
	total_medals as (
		SELECT g.games, g.region, 
		COALESCE(g.gold_medals,0) as gold, -- Using COALESCE to replace null with 0
		COALESCE(s.silver_medals,0) as silver, 
		COALESCE(b.bronze_medals,0) as bronze
		FROM total_gold	g						-- Joining the temp tables for getting the values
		LEFT JOIN total_silver s
		ON g.region=s.region and g.games=s.games
		LEFT JOIN total_bronze b
		ON g.region=s.region and g.games=s.games)

SELECT DISTINCT games,
	CONCAT(FIRST_VALUE(region) OVER (PARTITION BY games ORDER BY gold DESC),' - ',FIRST_VALUE(gold) OVER (PARTITION BY games ORDER BY gold DESC)) as Max_gold,
	CONCAT(FIRST_VALUE(region) OVER (PARTITION BY games ORDER BY silver DESC),' - ',FIRST_VALUE(silver) OVER (PARTITION BY games ORDER BY silver DESC)) as Max_silver,
	CONCAT(FIRST_VALUE(region) OVER (PARTITION BY games ORDER BY bronze DESC),' - ',FIRST_VALUE(bronze) OVER (PARTITION BY games ORDER BY bronze DESC)) as Max_bronze
FROM total_medals
ORDER BY games;



--Q.17) IDENTIFY WHICH COUNTRY WON THE MOST GOLD, MOST SILVER, MOST BRONZE MEDALS AND THE MOST MEDALS IN EACH OLYMPIC GAMES.

WITH total_gold as (
		SELECT oh.games, r.region, COUNT(oh.medal) as gold_medals -- Getting count for gold medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Gold'
		GROUP BY r.region, oh.games),
	
	total_silver as (
		SELECT oh.games, r.region, COUNT(oh.medal) as silver_medals -- Getting count for silver medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Silver'
		GROUP BY r.region, oh.games),
	
	total_bronze as (
		SELECT oh.games, r.region, COUNT(oh.medal) as bronze_medals -- Getting count for bronze medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Bronze'
		GROUP BY r.region, oh.games),
	
	total_medals as (
		SELECT g.games, g.region, 
		COALESCE(g.gold_medals,0) as gold, -- Using COALESCE to replace null with 0
		COALESCE(s.silver_medals,0) as silver, 
		COALESCE(b.bronze_medals,0) as bronze
		FROM total_gold	g						-- Joining the temp tables for getting the values
		LEFT JOIN total_silver s
		ON g.region=s.region and g.games=s.games
		LEFT JOIN total_bronze b
		ON g.region=b.region and g.games=b.games),

	max_medals as (
		SELECT oh.games, r.region, COUNT(oh.medal) as cnt_medals -- Getting count for total medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal<>'NA'
		GROUP BY oh.games, r.region)

SELECT DISTINCT t.games,
	CONCAT(FIRST_VALUE(t.region) OVER (PARTITION BY t.games ORDER BY t.gold DESC),' - ',FIRST_VALUE(t.gold) OVER (PARTITION BY t.games ORDER BY t.gold DESC)) as Max_gold,
	CONCAT(FIRST_VALUE(t.region) OVER (PARTITION BY t.games ORDER BY t.silver DESC),' - ',FIRST_VALUE(t.silver) OVER (PARTITION BY t.games ORDER BY t.silver DESC)) as Max_silver,
	CONCAT(FIRST_VALUE(t.region) OVER (PARTITION BY t.games ORDER BY t.bronze DESC),' - ',FIRST_VALUE(t.bronze) OVER (PARTITION BY t.games ORDER BY t.bronze DESC)) as Max_bronze,
	CONCAT(FIRST_VALUE(m.region) OVER (PARTITION BY t.games ORDER BY m.cnt_medals DESC),' - ',FIRST_VALUE(m.cnt_medals) OVER (PARTITION BY t.games ORDER BY m.cnt_medals DESC)) as Max_medals
FROM total_medals t
JOIN max_medals m ON t.games=m.games
ORDER BY games;



--Q.18) WHICH COUNTRIES HAVE NEVER WON GOLD MEDAL BUT HAVE WON SILVER/BRONZE MEDALS?

WITH total_no_medals as (
		SELECT r.region, COUNT(oh.medal) as medals -- Getting count for gold medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal<>'NA'
		GROUP BY r.region),

	total_gold as (
		SELECT r.region, COUNT(oh.medal) as gold_medals -- Getting count for gold medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Gold'
		GROUP BY r.region),

	total_silver as (
		SELECT r.region, COUNT(oh.medal) as silver_medals -- Getting count for silver medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Silver'
		GROUP BY r.region),

	total_bronze as (
		SELECT r.region, COUNT(oh.medal) as bronze_medals -- Getting count for bronze medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal='Bronze'
		GROUP BY r.region),

	temp_table as (
		SELECT tm.region,
			COALESCE(g.gold_medals,0) as gold, 
			COALESCE(s.silver_medals,0) as silver, 
			COALESCE(b.bronze_medals,0) as bronze
		FROM total_no_medals tm       -- Joining the temp tables for getting the values
		LEFT JOIN total_gold g ON tm.region=g.region
		LEFT JOIN total_silver s ON tm.region=s.region
		LEFT JOIN total_bronze b ON tm.region=b.region)
SELECT * 
FROM temp_table 
WHERE gold = 0 AND (silver > 0 or bronze > 0)
ORDER BY gold DESC, silver DESC, bronze DESC;



--Q.19) IN WHICH SPORT/EVENT, INDIA HAS WON HIGHEST MEDALS.

WITH cte as (
		SELECT oh.sport, r.region as team, COUNT(oh.medal) as no_of_medals
		FROM Olympics..OLYMPICS_HISTORY oh
		JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
		ON oh.NOC=r.NOC
		WHERE medal <> 'NA' AND team = 'India'
		GROUP BY oh.sport, r.region),
	cte2 as (
		SELECT *, RANK() OVER (ORDER BY no_of_medals DESC) as rnk
		FROM cte)
SELECT sport, no_of_medals
FROM cte2
WHERE rnk=1;



--Q.20) BREAK DOWN ALL OLYMPIC GAMES WHERE INDIA WON MEDAL FOR HOCKEY AND HOW MANY MEDALS IN EACH OLYMPIC GAMES.

SELECT r.region as team, oh.sport, oh.games, COUNT(oh.medal) as no_of_medals
FROM Olympics..OLYMPICS_HISTORY oh
JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
ON oh.NOC=r.NOC
WHERE medal <> 'NA' and region = 'India' and sport = 'Hockey'
GROUP BY region, sport, games
ORDER BY no_of_medals DESC;