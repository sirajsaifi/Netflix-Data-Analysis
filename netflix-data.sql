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

-- Count the number of Movies vs TV Shows
select type, count(*) from netflix_data group by type;

-- Find the most common rating for movies and TV shows
select type, rating from
	(select type, rating, count(*), RANK() over(partition by type order by count(*) desc) as ranking
		from netflix_data
			group by 1, 2) as t1
	where ranking = 1;
    
-- List all movies released in a specific year (e.g., 2020)
select title as Movies from netflix_data where type = 'Movie' and release_year = '2020';

-- Identify the longest movie
select * from netflix_data where type = 'Movie' and duration = (select max(duration) from netflix_data);

-- Find content added in the last 5 years
select * from netflix_data where str_to_date(date_added, '%M %d, %Y') >= date_sub(curdate(), interval 5 YEAR);

-- Find all the movies/TV shows by director 'Rajiv Chilaka'!
select title, director from netflix_data where director like '%Rajiv Chilaka%'; 

-- List all TV shows with more than 5 seasons
select * from netflix_data where type = 'TV Show' and cast(substring_index(duration, ' ', 1)as unsigned) > 5;

-- Count the number of content items in each genre
select genre, count(*) as total_content
	from (
		select trim(value) as genre from netflix_data,
        json_table(
			concat('["', replace(listed_in, ', ', '","'), '"]'),
            '$[*]' columns (value varchar(100) path '$')
		)as genres
	) as genre_list
    group by genre
    order by total_content desc;

-- Find each year and the average numbers of content added in India on netflix. return top 5 year with highest avg content release!
select extract(YEAR from str_to_date(date_added, '%M %d, %Y'))as year,
round(cast(count(*) as unsigned)/cast((select count(*) from netflix_data where country='India')as unsigned)*100, 2) as avg_release
from netflix_data where country='India' group by 1 order by 2 desc limit 5;

-- List all movies that are documentaries
select title from netflix_data where type = 'Movie' and listed_in like '%Documentaries%';

-- Find all content without a director
select * from netflix_data where director = '';

-- Find how many movies actor 'Salman Khan' appeared in last 10 years!
select count(*) from netflix_data where type = 'Movie' and cast like '%Salman Khan%' and release_year >= extract(YEAR from current_date) - 10;

-- Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.
select category, count(*) from (
select *,
	case
		when description like '%kill%' or description like '%violence%' then 'Bad'
        else 'Good'
	end as category
from netflix_data
) as category_count group by 1;

