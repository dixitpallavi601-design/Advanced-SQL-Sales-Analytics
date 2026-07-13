/*---Product Report

---PURPOSE: This report consolidates key customer metrics and behaviour

-------HIGHLIGHTS------

1.Gather essential fileds such as Name, Age,transaction details

2.Segment customers into categoies (VIP,Regular,New)

3.Total Orders
1.total sales
2. total qty purchased 
3.total products
lifespan(in months)

4.Calculate valuable KPIs
1.Recency(momths since last order)
2.Avg Order Value
3.avg monthly spend*/



/*--------------------------------------------------------------------------------------------------------------------------------------- 
(1).Base query : Retrieves core columns from fact_sales and dim_customers tables
---------------------------------------------------------------------------------------------------------------*/
Create view product_report AS
WITH base_query AS
(select 
s.order_number,
s.order_date,
s.customer_key,
s.sales_amount,
s.qty,
p.product_code,
p.product_name,
p.category,
p.subcategory,
p.cost
from dbo.sales s
left join dbo.products p	
ON s.product_code = p.product_code
where order_date is not null),	--- only consider orders with valid dates

/*----------------------------------------------------------------------------------------------------------------------------------------
(2) Product aggregation : Summarizes sales data by product level
---------------------------------------------------------------------------------------------------------*/
product_aggregation AS 
(Select 
product_code,
product_name,
category, 
subcategory,
cost,
datediff(month, min(order_date), max(order_date)) as lifespan,
max(order_date) as last_order_date,
count(distinct order_number) as total_orders,
count(distinct customer_key) as total_customers,
sum(sales_amount) as total_sales,
sum(qty) as total_quantity,
round(AVG(CAST(sales_amount AS FLOAT)/NULLIF(qty,0)),2) as avg_selling_price
from Base_query
 group by product_code, product_name, category, subcategory, cost)
 
 
/*--------------------------------------------------------------------------------------------------------------
(3)Final query : Combines all product results into on output
---------------------------------------------------------------------------------------------------------------*/
select 
product_code,
product_name,
category,
subcategory,
cost,
last_order_date,
datediff(month, last_order_date, getdate()) as recency,
CASE WHEN total_sales >50000 THEN 'High performer'
	 WHEN total_sales >=10000 THEN 'Medium performer'
	 ELSE 'Low performer' 
	 END as product_segmentation,
	 lifespan,
	 total_orders,
	 total_sales,
	 total_quantity,
	 total_customers,
	 avg_selling_price,
	 
	 -----avg order revenue (AOR)----
	
	CASE when total_orders =0 then 0
    ELSE total_sales/total_orders
	END as avg_order_revenue,
	
	/*avg monthly revenue (AMR)*/
	CASE 
	WHEN lifespan=0 THEN 0
	ELSE total_sales/lifespan
	END as avg_monthly_revenue
	from product_aggregation;

SELECT * FROM product_report;
