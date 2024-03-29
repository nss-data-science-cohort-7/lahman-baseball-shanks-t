-- #1
-- select distinct(p.playerid), p.namefirst, p.namelast, s.schoolname, 
-- s.schoolcity, sum(salary::NUMERIC::Money) as total_salary
-- from people p
-- left join collegeplaying cp
-- on p.playerid = cp.playerid
-- left join schools s
-- on s.schoolid = cp.schoolid
-- left join salaries sa
-- on sa.playerid = p.playerid
-- where s.schoolname like 'Vanderbilt%'
-- group by 1,4,5


-- #2
-- drop table position_groups

-- -- create temp table position_groups as 
-- with p_groups as 
-- (
-- select p.playerid, p.namefirst, p.namelast, f.pos, f.po,
-- case 
-- 	when f.pos in ('SS', '1B', '2B', '3B') then 'Infield'
-- 	when f.pos in ('P', 'C') then 'Battery'
-- 	when f.pos = 'OF' then 'Outfiled'
-- 	else 'Other'
-- end as position_group
-- from people p
-- inner join fielding f
-- on p.playerid = f.playerid
-- group by p.playerid, f.pos, f.po
-- )
-- select position_group, sum(po) as po_by_group
-- from p_groups
-- group by 1

-- #3
-- with bins as (
-- 	select
-- 		generate_series(1920, 2000, 10) as lower,
-- 		generate_series(1930, 2010, 10) as upper),
-- 		avg_per_year as (
-- 		select (sum(so)/sum(g)) as so_game_year, (sum(hr)/sum(g)) as hr_game_year, yearid 
-- 		from teams t
-- 		group by so, yearid, g
-- 		order by yearid desc
-- 		)
-- 	select lower, upper,  round(sum(so_game_year)/count(yearid), 2) as avg_so_by_game, 
-- 	round(sum(hr_game_year)/count(yearid), 2) as avg_hr_by_game
-- 		from bins
-- 			left join avg_per_year apy
-- 				on yearid >= lower
-- 				and yearid < upper
-- group by lower, upper
-- order by lower


-- #4
-- select p.playerid, p.namefirst, p.namelast, to_char((b.sb/b.cs+b.sb), 'fm99%') as sb_perc, b.sb, b.cs
-- from people p
-- inner join batting b
-- using(playerid)
-- where b.yearid = 2016 and b.sb > 20
-- order by sb_perc desc

-- #5

-- a
with least_wins as (
	select yearid, teamid, w, l, wswin
	from teams
	where wswin = 'Y'
	order by w
	limit 1
),
most_wins as (
	select yearid, teamid, w, l, wswin
	from teams
	where wswin = 'N'
	order by w desc
	limit 1
)
select *
from least_wins
union
select *
from most_wins;

-- b
-- with ws_winners as (
-- 	select yearid, teamid, w, l, wswin
-- 	from teams
-- 	where wswin = 'Y' and yearid >= 1970 and yearid <= 2016
-- ),
with most_wins as (
	select 
		yearid, 
		teamid, 
		w, 
		l, 
		wswin,
		RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS win_rank
	from teams
	where yearid >= 1970 and yearid <= 2016
)
select 
	round((COUNT(DISTINCT CASE WHEN wswin = 'Y' THEN yearid END) * 100.0 / COUNT(DISTINCT yearid)), 2) 
	AS perc_most_wins_and_wswin
from most_wins
where win_rank = 1;


-- #6

with manager_awards as (
	select 
		p.playerid,
		p.namefirst,
		p.namelast,
		m.teamid,
		aw.yearid,
		aw.lgid
	from people p
	inner join awardsmanagers aw
	using(playerid)
	inner join managers m
	using(playerid)
	where aw.awardid = 'TSN Manager of the Year'
),
manager_league_counts as (
	select
		playerid,
		namefirst,
		namelast,
	ARRAY_AGG(distinct teamid) as teams,
	ARRAY_AGG(distinct yearid) as years,
	count(distinct lgid) as lg_count
	from manager_awards
	group by playerid, namefirst, namelast
)
select playerid, namefirst, namelast, teams, years
from manager_league_counts
where lg_count = 2
	
-- #7

with pitcher_stats as (
	select 
		pi.yearid,
		p.playerid, 
		p.namefirst,
		p.namelast,
		pi.so,
		pi.gs,
		pi.teamid,
-- 		count(distinct pi.teamid) as teams,
		sa.salary
	from people p
	inner join pitching pi using(playerid)
-- 	inner join salaries sa using(playerid)
	inner join salaries sa on pi.playerid = sa.playerid and pi.yearid = sa.yearid
	where pi.yearid = 2016 and pi.gs > 10
-- 	group by pi.yearid, p.playerid, pi.so, pi.gs, pi.teamid, sa.salary
-- 	order by teams desc
),
total_salaries as (
	select
	playerid,
	namefirst,
	namelast,
	ARRAY_AGG(distinct teamid) as teams,
	sum(distinct(salary)::NUMERIC::Money) as total_salary
	from pitcher_stats
	group by playerid, namefirst, namelast
)
select playerid, namefirst, namelast, total_salary, teams
from total_salaries
order by total_salary desc

-- select playerid, p.namefirst, p.namelast, count(distinct pi.teamid)
-- from people p
-- inner join pitching pi using(playerid)
-- where pi.yearid = 2016
-- group by playerid, p.namefirst, p.namelast
-- order by count desc

-- #8

with hitters as (
	select 
		p.playerid, 
		p.namefirst,
		p.namelast,
		ba.h
	from people p
	inner join batting ba using(playerid)
),
total_hits as (
	select
		playerid,
		namefirst,
		namelast,
		sum(h) as career_hits
	from hitters
	group by playerid, namefirst, namelast
	order by career_hits desc
)
select playerid, namefirst, namelast, career_hits,
	case 
		when hoa.inducted = 'N' then null
		else hoa.yearid
	end as year_inducted
from total_hits th
inner join halloffame hoa using(playerid)
where career_hits >= 3000
group by playerid, namefirst, namelast, career_hits, inducted, hoa.yearid
order by career_hits desc

