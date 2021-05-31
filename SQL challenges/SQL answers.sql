-- Query 1
with ts_lag as
(
	select
		*,
		lag(unix_timestamp, 1) over (partition by user_id order by unix_timestamp) as prev_ts,
		row_number() over (partition by user_id order by unix_timestamp desc) as ord_desc
	from query_one
)

select
	a.*,
	a.unix_timestamp - a.prev_ts as ts_delta
from ts_lag a
where ord_desc = 1
order by user_id
limit 50;


-- Query 2
SELECT
	100*SUM(CASE WHEN m.user_id IS null THEN 1 ELSE 0 END)/COUNT(*) as WEB_ONLY,
	100*SUM(CASE WHEN w.user_id IS null THEN 1 ELSE 0 END)/COUNT(*) as MOBILE_ONLY,
	100*SUM(CASE WHEN m.user_id IS NOT null AND w.user_id IS NOT null THEN 1 ELSE 0 END)/COUNT(*) as BOTH
FROM
(SELECT distinct user_id FROM query_two_web ) w
FULL OUTER JOIN
(SELECT distinct user_id FROM query_two_mobile ) m
ON m.user_id = w.user_id;


-- Query 3
with purchase_hist as
(
	select
		*,
		row_number() over (partition by user_id order by date asc) as purchase_no
	from query_three
)

select *
from purchase_hist
where purchase_no = 10;


-- Query 4
with user_spending as
(
	select *
	from query_four_march
	union all
	select *
	from query_four_april
)

, total_user_spending as
(
	select
		user_id,
		sum(transaction_amount) as total_spent
	from user_spending
	group by 1
	order by 1
)

select
	user_id,
	date,
	sum(transaction_amount) over (partition by user_id order by date asc) as cumulative_total
from user_spending
order by 1,2;


-- Query 5
select
--	a.user_id,
	avg(a.transaction_amount) as avg_value,
	percentile_cont(0.5) within group (order by a.transaction_amount) as median_value
from query_five_transactions a
inner join query_five_users b on a.user_id = b.user_id and a.transaction_date = b.sign_up_date
--group by 1


-- query 6.1

with country_users as
(
	select
		country,
		count(user_id) as users
	from query_six
	group by 1
)

select
	*,
	row_number() over (order by users asc) count_asc,
	row_number() over (order by users desc) count_desc
from country_users;


-- Query 6.2
SELECT user_id,
       created_at,
       country
FROM  (SELECT *,
              ROW_NUMBER() OVER (PARTITION BY country ORDER BY created_at) count_asc,
              ROW_NUMBER() OVER (PARTITION BY country ORDER BY created_at desc) count_desc
       FROM query_six
       ) tmp
WHERE count_asc = 1 or count_desc = 1
LIMIT 5;
