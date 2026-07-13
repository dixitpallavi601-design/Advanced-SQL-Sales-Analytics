---Sales Performance over time ---- TRENDS
---Month_Wise and Year_Wise
select
DATETRUNC(MONTH,order_date) order_month,
DATETRUNC(YEAR,order_date) order_Year,
SUM(sales_amount) AS Total_sales,
COUNT(customer_id) AS Total_customers,
SUM(qty) AS Total_qty
from dbo.sales
where order_date is not null
group by DATETRUNC(MONTH,order_date),DATETRUNC(YEAR,order_date)
order by DATETRUNC(MONTH,order_date),DATETRUNC(YEAR,order_date)

---Year_Wise
WITH Product_History
AS (select
DATETRUNC(Year,order_date) order_month,
SUM(sales_amount) AS Total_sales,
COUNT(customer_id) AS Total_customers,
SUM(qty) AS Total_qty
from dbo.sales
where order_date is not null
group by DATETRUNC(Year,order_date)
order by DATETRUNC(Year,order_date))

----Cumulutive Analysis
--Calculate total sales for each month
select
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales
from dbo.sales
where order_date is not null
group by DATETRUNC(month,order_date)
order by DATETRUNC(month,order_date)

--Running total of sales over time 
	select 
	order_date,
	Total_sales,
	SUM(total_sales) over (order by order_date) AS Running_total,
	Avg(avg_price) over (order by order_date) AS moving_avg 
	from 
	(select
	DATETRUNC(month,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) AS avg_price
	from dbo.sales
	where order_date is not null
	group by DATETRUNC(month,order_date)
	)t
	
/*-----Performance Analysis 
-- Analyze the yearly performance of products by comparing each product's sales
to both its avg sales performance and the previous year's sales.---*/

With yearly_sales AS
(select 
YEAR(s.order_date)AS order_year,
p.product_name,
SUM(s.sales_amount) current_sales 
from dbo.sales s
left join dbo.products p
ON p.product_code=s.product_code
where order_date is not null
group by YEAR(s.order_date),
p.product_name)

----CTE used
select
order_year,
product_name,
current_sales,
AVG(current_sales) over(Partition by product_name) avg_sales,
current_sales-AVG(current_sales) over(Partition by product_name) difference_avg,
CASE WHEN current_sales-AVG(current_sales) over(Partition by product_name)  > 0 THEN 'Above_avg'
     WHEN current_sales-AVG(current_sales) over(Partition by product_name)  < 0 THEN 'Below_avg'
	 ELSE 'Avg'
	 END avg_chng,
	 ------ Year over Year Analysis
	 LAG(current_sales)over(Partition by product_name order by order_year) pre_year_sales,
	 current_sales-LAG(current_sales)over(Partition by product_name order by order_year) py_diff,
	 CASE WHEN current_sales - LAG(current_sales)over(Partition by product_name order by order_year)>0 THEN'Increase'
	      WHEN current_sales - LAG(current_sales)over(Partition by product_name  order by order_year)<0 THEN'Decrease'
		  ELSE 'No chng'
		  END py_chng
from yearly_sales
order by product_name,order_year

------Part to whole Analysis
---Which categories contribute the most to overall sales
WITH category_sales AS
(Select 
p.category,
SUM(s.sales_amount) Total_sales
from dbo.sales s
left join dbo.products p
ON p.product_code = s.product_code
group by category)

select 
category,
Total_sales,
Sum(Total_sales) over() AS overall_sales,
CONCAT(ROUND((CAST (Total_sales as float)/Sum(Total_sales) over())*100,2),'%' )As percent_of_total
from category_sales
order by percent_Of_total desc

---Data segmentation in SQL
/*Segment products into cost ranges and
count how many products fall into each segment*/

Select 
product_code,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
     WHEN cost BETWEEN 100 AND  500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
	 END cost_rng
	 from dbo.products
/* Group Customers into three segments based  on their spending behaviour:
VIP:Customers with atleast 12 months of history and spending more than 5000
Regular:Customers with atleast 12 months of history but spending 5000 or less
New:Customers with a lifespan less than 12 months.
AND find total number of customers by each group
*/
 
    WITH customer_history AS
	(SELECT 
    c.customer_key,
    SUM(s.sales_amount) AS total_spent,
    MIN(s.order_date) AS First_order,
    MAX(s.order_date) AS Last_order,
	DATEDIFF(month,MIN(s.order_date),MAX(s.order_date) ) AS ordered_Months
FROM dbo.sales s
LEFT JOIN dbo.customers c 
ON s.customer_key = c.customer_key
GROUP BY c.customer_key)


select
customer_segments,
COUNT(Customer_key) AS Total_customers
FROM
(select 
Customer_key,
CASE WHEN ordered_months >= 12 AND total_spent >= 5000 THEN 'VIP'
    WHEN ordered_months >= 12 AND total_spent < 5000 THEN 'Regular'
     
	ELSE'New'
	 END  AS customer_segments
	 from customer_history)t
	 group by customer_segments 
	 order by total_customers DESC
	 
	








