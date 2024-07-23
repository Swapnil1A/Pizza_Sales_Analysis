--Total No. of Orders placed
select COUNT(*) as Total_Orders from orders

--Total Revenue generated from Pizza_Sales
SELECT SUM(o_details.quantity * pizzas.price) as Total_Revenue
from pizzas
JOIN order_details o_details ON o_details.pizza_id = pizzas.pizza_id

--Highest Priced Pizzas
select pizza_types.name , pizzas.price  from pizza_types
join pizzas on pizza_types.pizza_type_id=pizzas.pizza_type_id
order by pizzas.price desc
limit 1

--Common pizzas size ordered 
select pizzas.size,COUNT(order_details.order_details_id) as Order_Count from pizzas
join order_details on order_details.pizza_id = pizzas.pizza_id
group by pizzas.size
order by Order_Count desc

--5 Most Ordered Pizzas with their quantity
select pizza_types.name, COUNT(order_details.quantity) as Total_Quantity from pizza_types
join pizzas on pizzas.pizza_type_id = pizza_types.pizza_type_id
join order_details on pizzas.pizza_id=order_details.pizza_id
group by 1
order by Total_Quantity desc
limit 5;

--Total Quantity of Each Pizza category ordered
select pizza_types.category,  SUM(order_details.quantity) as Total_Quantity from pizza_types
join pizzas on pizzas.pizza_type_id = pizza_types.pizza_type_id
join order_details on pizzas.pizza_id=order_details.pizza_id
group by 1
order by Total_Quantity desc

--Distribution of orders as per Hour of the day
select extract(HOUR from time) as hour, Count(order_id) as Order_Count
from orders
group by hour
order by Order_Count desc

--Category-wise pizza ordered
select category, count(pizza_types.name) as Total_Pizzas from pizza_types
group by category

--Average quantity of pizzas ordered on per day basis
select round(avg(quantity),0) as Avg_order_per_day from
(select date,sum(order_details.quantity) as Quantity  from orders
join order_details on order_details.order_id=orders.order_id
group by date)


--top 3 most ordered pizza types based on revenue.
select pizza_types.name, pizza_types.category, SUM(order_details.quantity*pizzas.price) as Total_Revenue from pizza_types
join pizzas on pizzas.pizza_type_id=pizza_types.pizza_type_id
join order_details on order_details.pizza_id=pizzas.pizza_id
group by 1,2
order by Total_Revenue Desc
limit 3;

-- METHOD 1 : Percentage Contribution of each pizza_type to the total_Revenue generated
select pizza_types.category, ROUND(sum(order_details.quantity*pizzas.price)/(select SUM(order_details.quantity*pizzas.price) from order_details
join pizzas on pizzas.pizza_id=order_details.pizza_id),2)*100 as total_Percentage_Revenue

from pizza_types
join pizzas on pizzas.pizza_type_id=pizza_types.pizza_type_id
join order_details on order_details.pizza_id=Pizzas.pizza_id
group by pizza_types.category
order by total_Percentage_Revenue Desc

-- METHOD 2 : using cte..
with cte as(
    select  SUM(order_details.quantity*pizzas.price) as total_global_revenue from order_details
join pizzas on pizzas.pizza_id=order_details.pizza_id
),
cte_2 as(select pizza_types.category, ROUND(sum(order_details.quantity*pizzas.price)/(total_global_revenue),2)* 100 as Percentage_1 
	from cte,pizza_types
    join pizzas on pizzas.pizza_type_id=pizza_types.pizza_type_id
join order_details on order_details.pizza_id=Pizzas.pizza_id
group by pizza_types.category,total_global_revenue
	order by Percentage_1 desc
)
select * from cte_2

-- Cumulative Revenue generated over time : using cte
with cte as(
    select orders.date, sum(order_details.quantity*pizzas.price) as revenue
    from orders
    join order_details on orders.order_id=order_details.order_id
	join pizzas on pizzas.pizza_id=order_details.pizza_id
    group by orders.date
),
cte_2 as(
    select date, sum(revenue) over(order by date) as cumulative_sum from cte
)
select * from cte_2

--using sub_query
select date, sum(revenue) over(order by date) as cumulative_sum from(
  select orders.date, sum(order_details.quantity*pizzas.price) as revenue
    from orders
    join order_details on orders.order_id=order_details.order_id
	join pizzas on pizzas.pizza_id=order_details.pizza_id
    group by orders.date) as sales

--Top 3 most ordered pizza types based on revenue for each pizza category : using sub query
select name,category, Total_Revenue,Rn from
(select category, name,Total_Revenue, RANK() OVER(PARTITION by category order by Total_Revenue desc) as Rn
from
(select pizza_types.category,pizza_types.name,sum(order_details.quantity*pizzas.price) as Total_Revenue from pizza_types
join pizzas on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.category,pizza_types.name) as a) as b
where Rn<=3

--using cte
with cte as(
select pizza_types.pizza_type_id, name,category, sum(order_details.quantity*pizzas.price) as Revenue
from pizza_types
join pizzas on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details on order_details.pizza_id=pizzas.pizza_id
group by 1,category,name
),
cte_2 as(
select *,rank() over(partition by category order by Revenue desc) as rn 
from cte )
select * from cte_2
where rn<=3


