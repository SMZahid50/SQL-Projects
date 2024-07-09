# Olympic Data Analysis

## Introduction
An SQL analysis of 120 years of olympic data between 1896 and 2016

## Datasets Used
Two key [datasets](./data) for this case study
- <strong>athlete_events:</strong> Details of athlete and events
- <strong>noc_regions:</strong> Details of country according to their NOC

## Questions I Wanted To Answer From the Dataset:

### Q.1) How Many Olympics Games Have Been Held?
```mysql
Select COUNT(DISTINCT(Games)) as total_olympic_games
FROM Olympics..OLYMPICS_HISTORY;
```

Result:

![Q1](https://github.com/SMZahid50/SQL-Projects/assets/160847091/42270c72-6fa1-4239-982f-335a2fb98143)

### Q.2) List Down All Olympics Games Held So Far.
```mysql
Select DISTINCT Year, Season, City
FROM Olympics..OLYMPICS_HISTORY
ORDER BY Year;
```

Result:

![Q2](https://github.com/SMZahid50/SQL-Projects/assets/160847091/8f99c755-5a41-4955-b02f-ef5d27789888)

### Q.3) Mention The Total No Of Nations Who Participated In Each Olympics Game?
```mysql
Select oh.Games, COUNT(DISTINCT r.region) as total_countries
FROM Olympics..OLYMPICS_HISTORY oh
JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
ON oh.NOC=r.NOC
GROUP BY oh.Games
ORDER BY oh.Games;
```

Result:

![Q3](https://github.com/SMZahid50/SQL-Projects/assets/160847091/d03f6024-13d2-41a2-8b34-cab22e98534b)

### Q.4) Which Year Saw The Highest And Lowest No Of Countries Participating In Olympics?
```mysql
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
```

Result:

![Q4](https://github.com/SMZahid50/SQL-Projects/assets/160847091/6d640f2a-3cf4-4bad-b85e-b2376aa74b0b)

### Q.5) Which Nation Has Participated In All Of The Olympic Games?
```mysql
WITH cte as (
	SELECT r.region as country, 
			COUNT(DISTINCT games) as total_participated_games
	FROM Olympics..OLYMPICS_HISTORY oh
	JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
	ON oh.NOC=r.NOC
	GROUP BY r.region
)
SELECT * FROM cte WHERE total_participated_games=51;
```

Result:

![Q5](https://github.com/SMZahid50/SQL-Projects/assets/160847091/4415538f-b564-4fdb-98eb-75acf1448bae)

### Q.6) Identify The Sport Which Was Played In All Summer Olympics.
```mysql
WITH summer_sports as (
	SELECT sport, COUNT(DISTINCT games) as no_of_games
	FROM Olympics..OLYMPICS_HISTORY
	WHERE season = 'Summer'
	GROUP BY sport
)
SELECT * FROM summer_sports
WHERE no_of_games=29
ORDER BY no_of_games;
```

Result:

![Q6](https://github.com/SMZahid50/SQL-Projects/assets/160847091/991142dc-a40e-4097-b00e-eb392fd132c5)

### Q.7) Which Sports Were Just Played Only Once In The Olympics?
```mysql
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
```

Result:

![Q7](https://github.com/SMZahid50/SQL-Projects/assets/160847091/42a6af71-fe62-4340-a0c7-dcc1faaf02e2)

### Q.8) Fetch The Total No Of Sports Played In Each Olympic Games.
```mysql
SELECT DISTINCT games, COUNT(DISTINCT sport) as total_no_of_sport
FROM Olympics..OLYMPICS_HISTORY
GROUP BY games
ORDER BY total_no_of_sport DESC;
```

Result:

![Q8](https://github.com/SMZahid50/SQL-Projects/assets/160847091/1486cbf3-2384-499a-b359-032df63cc3cb)

### Q.9) Fetch Details Of The Oldest Athletes To Win A Gold Medal.
```mysql
WITH athlete_details as (
		SELECT name, sex, CAST(CASE WHEN age is null THEN '0' ELSE age END AS INT) as age, team, games, city, sport, event, medal
		FROM Olympics..OLYMPICS_HISTORY
		WHERE medal='Gold'),
	age_rnk as(
		SELECT athlete_details.*, RANK() OVER (ORDER BY age DESC) as rnk
		FROM athlete_details)
SELECT * FROM age_rnk WHERE rnk=1;
```

Result:

![Q9](https://github.com/SMZahid50/SQL-Projects/assets/160847091/fde0b0e3-65a4-42fb-8cc9-d54bb2aad355)

### Q.10) Find The Ratio Of Male And Female Athletes Participated In All Olympic Games.
```mysql
WITH t1 as (
	SELECT sex, COUNT(sex) as cnt
	FROM Olympics..OLYMPICS_HISTORY 
	GROUP BY sex),
	t2 as (
	SELECT *, row_number() over(order by cnt) as rn from t1),
	min_cnt as (SELECT cnt FROM t2 WHERE rn=1),
	max_cnt as (SELECT cnt FROM t2 WHERE rn=2)
SELECT CONCAT('1 : ',max_cnt.cnt/min_cnt.cnt) as ratio FROM min_cnt, max_cnt;
```

Result:

![Q10](https://github.com/SMZahid50/SQL-Projects/assets/160847091/a4cfaf96-b5c0-420d-8be3-e07c39f7234b)

### Q.11) Fetch The Top 5 Athletes Who Have Won The Most Gold Medals.
```mysql
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
```

Result:

![Q11](https://github.com/SMZahid50/SQL-Projects/assets/160847091/f9c33003-17d4-4762-8501-e3e45d48693a)

### Q.12) Fetch The Top 5 Athletes Who Have Won The Most Medals (Gold/silver/bronze).
```mysql
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
```

Result:

![Q12](https://github.com/SMZahid50/SQL-Projects/assets/160847091/8ae9cfe9-70f5-4ccf-b6f7-f31fbff609c0)

### Q.13) Fetch The Top 5 Most Successful Countries In Olympics. Success Is Defined By No Of Medals Won.
```mysql
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
```

Result:

![Q13](https://github.com/SMZahid50/SQL-Projects/assets/160847091/fc1dd23a-4e96-40cc-91a8-e9598dca4479)

### Q.14) List Down Total Gold, Silver And Broze Medals Won By Each Country.
```mysql
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
```
Result:

![Q14](https://github.com/SMZahid50/SQL-Projects/assets/160847091/83145a98-ca33-4a10-afac-c0fe8ca45919)

### Q.15) List Down Total Gold, Silver And Broze Medals Won By Each Country Corresponding To Each Olympic Games.
```mysql
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
```

Result:

![Q15](https://github.com/SMZahid50/SQL-Projects/assets/160847091/3ec5c9c4-35cc-4f46-91be-539b5217c3e6)

### Q.16) Identify Which Country Won The Most Gold, Most Silver And Most Bronze Medals In Each Olympic Games.
```mysql
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
```

Result:

![Q16](https://github.com/SMZahid50/SQL-Projects/assets/160847091/7897afae-6dad-402c-890d-ce201470fb69)

### Q.17) Identify Which Country Won The Most Gold, Most Silver, Most Bronze Medals And The Most Medals In Each Olympic Games.
```mysql
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
```

Result:

![Q17](https://github.com/SMZahid50/SQL-Projects/assets/160847091/3909fbbd-e66c-4335-85b4-3774487ecd78)

### Q.18) Which Countries Have Never Won Gold Medal But Have Won Silver/bronze Medals?
```mysql
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
```

Result:

![Q18](https://github.com/SMZahid50/SQL-Projects/assets/160847091/00c73668-cc90-4975-949c-81cc9bafede6)

### Q.19) In Which Sport/event, India Has Won Highest Medals.
```mysql
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
```

Result:

![Q19](https://github.com/SMZahid50/SQL-Projects/assets/160847091/d24e8828-b706-4fcd-a3d3-3d3eab615ff2)

### Q.20) Break Down All Olympic Games Where India Won Medal For Hockey And How Many Medals In Each Olympic Games.
```mysql
SELECT r.region as team, oh.sport, oh.games, COUNT(oh.medal) as no_of_medals
FROM Olympics..OLYMPICS_HISTORY oh
JOIN Olympics..OLYMPICS_HISTORY_NOC_REGIONS r
ON oh.NOC=r.NOC
WHERE medal <> 'NA' and region = 'India' and sport = 'Hockey'
GROUP BY region, sport, games
ORDER BY no_of_medals DESC;
```

Result:

![Q20](https://github.com/SMZahid50/SQL-Projects/assets/160847091/b44b5071-74e1-428a-a632-ca7d8554f4e1)
