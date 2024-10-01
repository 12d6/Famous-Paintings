select * from artist;
select * from canvas_size;
select * from image_link;
select * from museum;
select * from museum_hours;
select * from subject;
select * from work;




--1) Fetch all the paintings which are not displayed on any museums?
select name from work where museum_id  is null
--2) Are there museuems without any paintings

select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id)
-- 3) How many paintings have an asking price same as the regular price?
select * from product_size
	where sale_price = regular_price;
-- 4)Identify the paintings whose asking price is less than 50% of its regular price

select * from product_size
	where sale_price < regular_price*(0.5);
-- 5)Which canva size costs the most?

select x.label as canva , x.sale_price from 
(select c.*, ps.sale_price, 
rank() over(order by sale_price desc )as rnk
from canvas_size c join product_size ps on c.size_id::text=ps.size_id)x 
where x.rnk=1
-- 6)Delete duplicate records from work, product_size, subject and image_link tables
delete from work 
	where ctid not in (select min(ctid)
						from work
						group by work_id );
delete from product_size 
	where ctid not in (select min(ctid)
						from product_size
						group by work_id, size_id )
delete from subject 
	where ctid not in (select min(ctid)
						from subject
						group by work_id, subject );

delete from image_link 
	where ctid not in (select min(ctid)
						from image_link
						group by work_id );

--7)Identify the museums with invalid city information in the given dataset
select * from museum where city ~ '^[0-9]';
--8)Museum_Hours table has 1 invalid entry. Identify it and remove it.
	delete from museum_hours 
	where ctid not in (select min(ctid)
						from museum_hours
						group by museum_id, day );
						
-- 9) Fetch the top 10 most famous painting subject

select * from(select s.subject,count(subject)
,rank() over( order by  count(subject) desc) as rnk
from subject s join work w on s.work_id=w.work_id group by s.subject )x where rnk<=10

-- 10) Identify the museums which are open on both Sunday and Monday. Display museum name, city

SELECT name,city 
FROM museum 
WHERE museum_id in  (
    SELECT museum_id 
    FROM museum_hours m1 
    WHERE day = 'Sunday' 
    AND EXISTS (
        SELECT 1 
        FROM museum_hours m2 
        WHERE m2.museum_id = m1.museum_id 
        AND day = 'Monday'
    )
);
-- 11) How many museums are open every single day?
select name 
from museum 
where museum_id IN (
SELECT museum_id
FROM museum_hours 
group by museum_id 
having count(museum_id)=7 
);
select count(2)
	from (select museum_id, count(1)
		  from museum_hours
		  group by museum_id
		  having count(1) = 7) x;


-- 12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

select name,city,country,w.painting_count  
from museum m  
join(
select museum_id,count(1) as painting_count,
rank() over (order by count(1) desc) as rnk
from work group by 1) w
on w.museum_id=m.museum_id where rnk<=5 ;

-- 13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select a.full_name,a.nationality,x.artist_count
from artist a 
join
 (select artist_id ,count(1) as artist_count
,rank() over(order by count(1) desc ) as rnk
from work
group by 1)x 
on x.artist_id= a.artist_id 
where rnk<=5;

-- 14) Display the 3 least popular canva sizes
--my answer
select * from canvas_size;
select label from canvas_size cs
join(
select size_id , count(size_id),
rank() over (order by count(1)) as rnk
from product_size group by 1) ps on cs.size_id::text=ps.size_id
where ps.rnk<4;
-- original answer

select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id::text = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;




-- 15)Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

select * from(SELECT m.name,  m.state,mh.museum_id,mh.day,
    (TO_TIMESTAMP(close, 'HH12:MI AM') - TO_TIMESTAMP(open, 'HH12:MI AM')) AS duration,
	rank() over (order  by   (TO_TIMESTAMP(close, 'HH12:MI AM') - TO_TIMESTAMP(open, 'HH12:MI AM'))  desc)as rnk
	from museum_hours mh 
	join  museum m  on
	mh.museum_id= m.museum_id)x where x.rnk=1
	
-- 16) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.

with  ct_city as(
select city ,count(museum_id) ,
rank() over (order by count(museum_id) desc)as rnk
from museum 
group by  city ),

 ct_country as(
select country ,count(museum_id) ,
rank() over (order by count(museum_id) desc)as rnk
from museum 
group by  1)

select  string_agg(distinct ct.country,' , '),string_agg(c.city,' , ') from  ct_city c cross join ct_country ct where c.rnk=1 and ct.rnk=1

