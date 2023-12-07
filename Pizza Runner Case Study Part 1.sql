// Pizza Metrics Part A

//    How many pizzas were ordered?
SELECT COUNT(*) FROM customer_orders;
    
//    How many unique customer orders were made?
SELECT COUNT(DISTINCT ORDER_ID) FROM customer_orders;

//    How many successful orders were delivered by each runner?
SELECT COUNT(DISTINCT ORDER_ID) as orders_delivered, RUNNER_ID   
FROM runner_orders
WHERE CASE WHEN LOWER(CANCELLATION) LIKE '%cancellation%' THEN 1 ELSE 0 END  = 0
GROUP BY RUNNER_ID;
    
//    How many of each type of pizza was delivered?
SELECT COUNT(PIZZA_ID), PIZZA_ID
FROM runner_orders as ro
JOIN customer_orders as co ON ro.order_id = co.order_id
WHERE (
    SELECT CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END
) = 0
GROUP BY PIZZA_ID;
    
//    How many Vegetarian and Meatlovers were ordered by each customer?

SELECT CUSTOMER_ID,
       COALESCE(MAX(CASE WHEN PIZZA_NAME = 'Meatlovers' THEN pizza_count END), 0) AS Meatlovers_count,
       COALESCE(MAX(CASE WHEN PIZZA_NAME = 'Vegetarian' THEN pizza_count END), 0) AS Vegetarian_count
FROM (
    SELECT COUNT(co.PIZZA_ID) AS pizza_count,
           CUSTOMER_ID,
           PIZZA_NAME
    FROM customer_orders co
    JOIN PIZZA_NAMES pn ON co.pizza_id = pn.pizza_id
    GROUP BY CUSTOMER_ID, PIZZA_NAME
) AS subquery
GROUP BY CUSTOMER_ID;
    
//   What was the maximum number of pizzas delivered in a single order?
SELECT COUNT(PIZZA_ID), co.ORDER_ID
FROM runner_orders as ro
JOIN customer_orders as co ON ro.order_id = co.order_id
WHERE (
    SELECT CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END
) = 0
GROUP BY co.ORDER_ID
ORDER BY COUNT(PIZZA_ID) DESC
LIMIT 1;
    
//    For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT CUSTOMER_ID,
       COALESCE(MAX(CASE WHEN digit_indicator = 'Altered' THEN pizza_count END),0) AS Altered_pizza_count,
       COALESCE(MAX(CASE WHEN digit_indicator = 'Stock' THEN pizza_count END),0) AS Stock_pizza_count
FROM (
    SELECT COUNT(PIZZA_ID) AS pizza_count,
           CUSTOMER_ID,
           CASE WHEN REGEXP_LIKE(exclusions, '[0-9]') OR REGEXP_LIKE(extras, '[0-9]') THEN 'Altered' ELSE 'Stock' END AS digit_indicator
    FROM runner_orders ro
    JOIN customer_orders co ON ro.order_id = co.order_id
    WHERE (
        SELECT CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END
    ) = 0
    GROUP BY CUSTOMER_ID, digit_indicator
) AS subquery
GROUP BY CUSTOMER_ID;

//    How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(PIZZA_ID)
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE 
    (
        CASE WHEN LOWER(ro.cancellation) LIKE '%cancellation%' THEN 1 ELSE 0 END
    ) = 0
    AND
    (
        CASE WHEN REGEXP_LIKE(co.exclusions, '[0-9].*') AND REGEXP_LIKE(co.extras, '[0-9].*') THEN 1 ELSE 0 END
    ) = 1;
    
//    What was the total volume of pizzas ordered for each hour of the day?
SELECT COUNT(DISTINCT ORDER_ID), EXTRACT(HOUR FROM ORDER_TIME) AS hour_of_day
FROM customer_orders
GROUP BY hour_of_day;
    
//    What was the volume of orders for each day of the week?
SELECT COUNT(DISTINCT ORDER_ID), DAYNAME(ORDER_TIME) AS day_of_week
FROM customer_orders
GROUP BY day_of_week;