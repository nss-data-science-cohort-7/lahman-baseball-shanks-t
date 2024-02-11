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
with bins as (
	select
		generate_series(1920, 2000, 10) as lower,
		generate_series(1930, 2010, 10) as upper),
		avg_per_year as (
		select (sum(so)/sum(g)) as so_game_year, (sum(hr)/sum(g)) as hr_game_year, yearid 
		from teams t
		group by so, yearid, g
		order by yearid desc
		)
	select lower, upper,  round(sum(so_game_year)/count(yearid), 2) as avg_so_by_game, 
	round(sum(hr_game_year)/count(yearid), 2) as avg_hr_by_game
		from bins
			left join avg_per_year aspy
				on yearid >= lower
				and yearid < upper
group by lower, upper
order by lower


-- #4

