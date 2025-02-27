create database netflix;

use netflix;
create table netflix_data (
	show_id varchar(6),
    type varchar(10),
    title varchar(150),
	director varchar(208),
	cast varchar(1000),
	country varchar(150),
	date_added varchar(50),
	release_year int,
	rating varchar(10),
	duration varchar(15),
	listed_in varchar(100),
	description varchar(250)
);

load data infile 'netflix_titles.csv'
into table netflix_data
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

select * from netflix_data;

-- 1. Count the number of Movies vs TV Shows

select 
	type,
    count(*)
from 
	netflix_data
group by 1;


-- 2. Find the most common rating for movies and TV shows

select 
	type, 
    rating 
from 
	(
    select 
		type, 
        rating, 
        count(*), 
        rank() over(partition by type order by count(*) desc) as ranking 
	from 
		netflix_data 
	group by 1, 2
    ) as t1 
where 
	ranking = 1;
        
        
-- 3. List all movies released in a specific year (e.g., 2020)

select * 
from 
	netflix_data 
where 
	type = 'Movie' and release_year = '2020';


-- 4. Find the top 5 countries with the most content on Netflix

select 
	country, 
	content, 
    count(*) 
from 
	(
	select 
		country, 
        trim(value) as content 
	from 
		netflix_data,
		json_table(
			concat('["', replace(listed_in, ', ', '","'), '"]'),
				'$[*]' columns (value varchar(100) path '$')) as contents
    ) as content_list 
group by 1,2 
order by count(*) 
limit 5;


-- 5. Identify the longest movie

select * 
from 
	netflix_data 
where 
	type = 'Movie' and duration = 
		(select max(duration) from netflix_data);


-- 6. Find content added in the last 5 years

select * 
from 
	netflix_data 
where 
	str_to_date(date_added, '%M %d, %Y') >= date_sub(curdate(), interval 5 year);


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

select * 
from 
	netflix_data 
where 
	director like '%Rajiv Chilaka%';


-- 8. List all TV shows with more than 5 seasons

select * 
from 
	netflix_data 
where 
	type = 'TV show' and cast(substring_index(duration, ' ', 1) as unsigned) > 5;


-- 9. Count the number of content items in each genre

select 
	genre, 
	count(*) as listed_genre 
from
	(select 
		trim(value) as genre 
    from 
		netflix_data,
		json_table(
			concat('["', replace(listed_in, ', ', '","'), '"]'),
			'$[*]' columns (value varchar(100) path '$')
		) as genres
	) as genre_list
group by 1 
order by 2 desc;


-- 10. List all movies that are documentaries

select 
	title as Movies 
from 
	netflix_data 
where 
	type = 'Movie' and listed_in like '%Documentaries%';


-- 11. Find all content without a director

select * 
from 
	netflix_data 
where 
	director = '';


-- 12. Find how many movies actor 'Salman Khan' appeared in last 10 years!

select 
	count(*) as Salman_Khan_Movies 
from 
	netflix_data 
where 
	type = 'Movie' 
and 
	cast like '%Salman Khan%' 
and 
	release_year >= extract(YEAR from current_date()) - 10;


-- 13. Find the top 10 actors who have appeared in the highest number of movies produced in India.

select 
	actor, 
	count(*) as Total_Movies 
from 
	(select 
		trim(value) as actor, 
		country, 
		type 
    from 
		netflix_data,
		json_table(
			concat('["', replace(cast, ', ', '","'), '"]'),
			'$[*]' columns (value varchar(1000) path '$')
        ) as actors
	) as actor_list
where 
	country = 'India' 
and 
	type = 'Movie' 
group by 1
order by 2 desc 
limit 10;


-- 14.Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.

select 
	Category, 
	count(*) as total 
from 
	(select *,
		case
		when description like '%violence%' or '%kill%' then 'Bad'
        else 'Good'
		end as Category
	from 
		netflix_data
	) as Category_table
group by 1;