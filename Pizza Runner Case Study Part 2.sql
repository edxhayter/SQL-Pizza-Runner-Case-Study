// Runner and Customer Experience

//    How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
show parameters like 'WEEK_START%';
alter session set WEEK_START = 5;

SELECT
  DATE_TRUNC('WEEK', registration_date) AS week_start,
  COUNT(runner_id) AS signups
FROM
  runners
GROUP BY
  week_start
ORDER BY
  week_start;

//    What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
  ro.runner_id,
  AVG(TIMESTAMPDIFF(MINUTE, co.ORDER_TIME, ro.PICKUP_TIME)) AS avg_time_difference_minutes
FROM
  CUSTOMER_ORDERS co
JOIN
  RUNNER_ORDERS ro ON co.order_id = ro.order_id
WHERE 
     (
        SELECT CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END
    ) = 0
GROUP BY
  ro.runner_id;

//    Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT
  ro.ORDER_ID,
  COUNT(PIZZA_ID),  
  AVG(TIMESTAMPDIFF(MINUTE, co.ORDER_TIME, ro.PICKUP_TIME)) AS avg_time_difference_minutes
FROM
  CUSTOMER_ORDERS co
JOIN
  RUNNER_ORDERS ro ON co.order_id = ro.order_id
WHERE 
     (
        SELECT CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END
    ) = 0
GROUP BY
  ro.ORDER_ID
ORDER BY AVG_TIME_DIFFERENCE_MINUTES DESC;
-- Seems to be that larger orders take longer to prepare
    
//    What was the average distance travelled for each customer?
SELECT co.CUSTOMER_ID, AVG(TO_DOUBLE(TRIM(ro.distance,'km'))) AS avg_distance
FROM CUSTOMER_ORDERS as co
JOIN
  RUNNER_ORDERS as ro ON co.order_id = ro.order_id
WHERE COALESCE(ro.distance, 'null') != 'null'
GROUP BY co.CUSTOMER_ID;


SELECT *
FROM CUSTOMER_ORDERS as co
JOIN
  RUNNER_ORDERS as ro ON co.order_id = ro.order_id
WHERE COALESCE(ro.distance, 'null') != 'null';

//    What was the difference between the longest and shortest delivery times for all orders?
WITH RankedResults AS (
  SELECT
    co.ORDER_ID,
    TO_DOUBLE(LEFT(DURATION, 2)) AS clean_duration,
    ROW_NUMBER() OVER (ORDER BY clean_duration) AS row_asc,
    ROW_NUMBER() OVER (ORDER BY clean_duration DESC) AS row_desc
  FROM
    CUSTOMER_ORDERS AS co
  JOIN
    RUNNER_ORDERS AS ro ON co.order_id = ro.order_id
  WHERE
    COALESCE(ro.distance, 'null') != 'null'
)
SELECT
    MAX(clean_duration) - MIN(clean_duration) AS duration_difference
FROM
  RankedResults;
    
//    What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    ro.runner_id,
    AVG(TO_DOUBLE(LEFT(DURATION, 2))) AS clean_duration
  FROM
    CUSTOMER_ORDERS AS co
  JOIN
    RUNNER_ORDERS AS ro ON co.order_id = ro.order_id
  WHERE
    COALESCE(ro.distance, 'null') != 'null'
  GROUP BY RUNNER_ID;
    
//    What is the successful delivery percentage for each runner?
SELECT RUNNER_ID, SUCCESS_RATE
FROM(
SELECT
  ro.runner_id,
  SUM(CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END) AS failed_count,
  SUM(CASE WHEN LOWER(ro.cancellation) NOT LIKE '%cancellation%' THEN 1 ELSE 0 END) AS success_count,
  (SUCCESS_COUNT/(FAILED_COUNT + SUCCESS_COUNT)) as success_rate
FROM
  CUSTOMER_ORDERS AS co
JOIN
  RUNNER_ORDERS AS ro ON co.order_id = ro.order_id
GROUP BY
  ro.runner_id);