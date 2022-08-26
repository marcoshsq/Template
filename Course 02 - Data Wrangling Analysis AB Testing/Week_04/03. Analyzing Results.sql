/* Analyzing Results

Log onto Mode Analytics and from the home page, create a new report by clicking on the green
plus sign button in the upper right-hand corner. Enter the starter code where provided for each
exercise. You may want to create a new tab for each exercise.

Please use the discussion forum for any questions and/or comments you might have. Once you
have tried the exercises, feel free to watch the solutions video. Good luck with your practice!

Note: When querying a table, remember to prepend dsv1069, which is the schema, or folder
that contains the course data. */

-- ************************************************************************************************

/* Exercise 1: Use the order_binary metric from the previous exercise, count the number of users
per treatment group for test_id = 7, and count the number of users with orders (for test_id 7) */

SELECT test_assignment
	,COUNT(user_id) AS users
	,SUM(order_binary) AS users_with_orders
FROM (
	SELECT assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
		,MAX(CASE 
				WHEN orders.created_at > assignments.event_time
					THEN 1
				ELSE 0
				END) AS order_binary
	FROM (
		SELECT event_id
			,event_time
			,user_id
			,MAX(CASE 
					WHEN parameter_name = 'test_id'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_id
			,MAX(CASE 
					WHEN parameter_name = 'test_assignment'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_assignment
		FROM dsv1069.events
		GROUP BY event_id
			,event_time
			,user_id
		ORDER BY event_id
		) assignments
	LEFT OUTER JOIN dsv1069.orders ON assignments.user_id = orders.user_id
	GROUP BY assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
	) user_level
WHERE test_id = 7
GROUP BY test_assignment;

-- ************************************************************************************************

/* Exercise 2: Create a new tem view binary metric. Count the number of users per treatment
group, and count the number of users with views (for test_id 7) */

SELECT test_assignment
	,COUNT(user_id) AS users
	,SUM(views_binary) AS views_binary
FROM (
	SELECT assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
		,MAX(CASE 
				WHEN VIEWS.event_time > assignments.event_time
					THEN 1
				ELSE 0
				END) AS views_binary
	FROM (
		SELECT event_id
			,event_time
			,user_id
			,MAX(CASE 
					WHEN parameter_name = 'test_id'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_id
			,MAX(CASE 
					WHEN parameter_name = 'test_assignment'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_assignment
		FROM dsv1069.events
		GROUP BY event_id
			,event_time
			,user_id
		ORDER BY event_id
		) assignments
	LEFT OUTER JOIN (
		SELECT *
		FROM dsv1069.events
		WHERE event_name = 'view_item'
		) VIEWS ON assignments.user_id = VIEWS.user_id
	GROUP BY assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
	) user_level
WHERE test_id = 7
GROUP BY test_assignment;

-- ************************************************************************************************

/* Exercise 3: Alter the result from EX 2, to compute the users who viewed an item WITHIN 30
days of their treatment event */

SELECT test_assignment
	,COUNT(user_id) AS users
	,SUM(views_binary) AS views_binary
	,SUM(views_binary_30d) AS views_binary_30d
FROM (
	SELECT assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
		,MAX(CASE 
				WHEN VIEWS.event_time > assignments.event_time
					THEN 1
				ELSE 0
				END) AS views_binary
		,MAX(CASE 
				WHEN (
						VIEWS.event_time > assignments.event_time
						AND DATE_PART('day', VIEWS.event_time - assignments.event_time) <= 30
						)
					THEN 1
				ELSE 0
				END) AS views_binary_30d
	FROM (
		SELECT event_id
			,event_time
			,user_id
			,MAX(CASE 
					WHEN parameter_name = 'test_id'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_id
			,MAX(CASE 
					WHEN parameter_name = 'test_assignment'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_assignment
		FROM dsv1069.events
		GROUP BY event_id
			,event_time
			,user_id
		ORDER BY event_id
		) assignments
	LEFT OUTER JOIN (
		SELECT *
		FROM dsv1069.events
		WHERE event_name = 'view_item'
		) VIEWS ON assignments.user_id = VIEWS.user_id
	GROUP BY assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
	) user_level
WHERE test_id = 7
GROUP BY test_assignment;

-- ************************************************************************************************

/* Exercise 4: Create the metric invoices (this is a mean metric, not a binary metric) and for test_id = 7

- The count of users per treatment group
- The average value of the metric per treatment group
- The standard deviation of the metric per treatment group */

SELECT test_id
	,test_assignment
	,COUNT(user_id) AS users
	,AVG(invoices) AS avg_invoices
	,STDDEV(invoices) AS stddev_invoices
FROM (
	SELECT assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
		,COUNT(DISTINCT CASE 
				WHEN orders.created_at > assignments.event_time
					THEN orders.invoice_id
				ELSE NULL
				END) AS invoices
		,COUNT(DISTINCT CASE 
				WHEN orders.created_at > assignments.event_time
					THEN orders.line_item_id
				ELSE NULL
				END) AS line_items
		,COALESCE(SUM(CASE 
					WHEN orders.created_at > assignments.event_time
						THEN orders.price
					ELSE 0
					END), 0) AS total_revenue
	FROM (
		SELECT event_id
			,event_time
			,user_id
			,MAX(CASE 
					WHEN parameter_name = 'test_id'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_id
			,MAX(CASE 
					WHEN parameter_name = 'test_assignment'
						THEN CAST(parameter_value AS INT)
					ELSE NULL
					END) AS test_assignment
		FROM dsv1069.events
		GROUP BY event_id
			,event_time
			,user_id
		ORDER BY event_id
		) assignments
	LEFT OUTER JOIN dsv1069.orders ON assignments.user_id = orders.user_id
	GROUP BY assignments.user_id
		,assignments.test_id
		,assignments.test_assignment
	) mean_metrics
GROUP BY test_id
	,test_assignment
ORDER BY test_id;
