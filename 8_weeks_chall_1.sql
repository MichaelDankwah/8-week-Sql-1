-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
  s.customer_id, 
  SUM(m.price) AS total_amount_spent
FROM 
  sales s
JOIN 
  menu m ON s.product_id = m.product_id
GROUP BY 
  s.customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT 
  customer_id, 
  COUNT(DISTINCT order_date) AS visit_days
FROM 
  sales
GROUP BY 
  customer_id;


-- 3. What was the first item from the menu purchased by each customer?

WITH first_purchase AS (
  SELECT 
    customer_id, 
    MIN(order_date) AS first_order_date
  FROM 
    sales
  GROUP BY 
    customer_id
)
SELECT *
FROM first_purchase; 

SELECT 
  s.customer_id, 
  m.product_name
FROM 
  sales s
JOIN 
  menu m ON s.product_id = m.product_id
WHERE 
  (s.customer_id, s.order_date, s.product_id) IN (
    SELECT 
      customer_id, 
      MIN(order_date) AS first_order_date, 
      MIN(product_id) AS first_product_id
    FROM 
      sales
    GROUP BY 
      customer_id
  )
ORDER BY 
  s.customer_id;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
  m.product_name,
  COUNT(s.product_id) AS purchase_count
FROM 
  sales s
JOIN 
  menu m ON s.product_id = m.product_id
GROUP BY 
  m.product_name
ORDER BY 
  purchase_count DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?

SELECT 
  pc.customer_id,
  (SELECT product_name 
   FROM (
     SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count
     FROM sales s
     JOIN menu m ON s.product_id = m.product_id
     WHERE s.customer_id = pc.customer_id
     GROUP BY s.customer_id, m.product_name
     ORDER BY purchase_count DESC
     LIMIT 1
   ) AS sub_query
  ) AS most_popular_item,
  MAX(pc.purchase_count) AS purchase_count
FROM (
  SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
) AS pc
GROUP BY pc.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase_after_join AS (
  SELECT 
    s.customer_id,
    m.product_name,
    s.order_date,
    m.price,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
  FROM 
    sales s
  JOIN 
    menu m ON s.product_id = m.product_id
  JOIN 
    members mem ON s.customer_id = mem.customer_id
  WHERE 
    s.order_date >= mem.join_date
)
SELECT 
  customer_id,
  product_name AS first_purchase_item,
  order_date AS first_purchase_date,
  price AS first_purchase_price
FROM 
  first_purchase_after_join
WHERE 
  purchase_rank = 1;


-- 7. Which item was purchased just before the customer became a member?

WITH last_purchase_before_join AS (
  SELECT 
    s.customer_id,
    m.product_name,
    s.order_date,
    m.price,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS purchase_rank
  FROM 
    sales s
  JOIN 
    menu m ON s.product_id = m.product_id
  JOIN 
    members mem ON s.customer_id = mem.customer_id
  WHERE 
    s.order_date < mem.join_date
)
SELECT 
  customer_id,
  product_name AS last_purchase_item,
  order_date AS last_purchase_date,
  price AS last_purchase_price
FROM 
  last_purchase_before_join
WHERE 
  purchase_rank = 1;



-- 8. What is the total items and amount spent for each member before they became a member?

WITH total_items_and_amount_before_join AS (
  SELECT 
    s.customer_id,
    COUNT(*) AS total_items,
    SUM(m.price) AS total_amount
  FROM 
    sales s
  JOIN 
    menu m ON s.product_id = m.product_id
  JOIN 
    members mem ON s.customer_id = mem.customer_id
  WHERE 
    s.order_date < mem.join_date
  GROUP BY 
    s.customer_id
)
SELECT 
  t.customer_id,
  t.total_items,
  t.total_amount
FROM 
  total_items_and_amount_before_join t;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points_earned AS (
  SELECT 
    s.customer_id,
    SUM(
      CASE 
        WHEN m.product_name = 'sushi' THEN m.price * 20  -- sushi has 2x multiplier
        ELSE m.price * 10  -- regular items
      END
    ) AS total_points
  FROM 
    sales s
  JOIN 
    menu m ON s.product_id = m.product_id
  GROUP BY 
    s.customer_id
)
SELECT 
  pe.customer_id,
  pe.total_points
FROM 
  points_earned pe;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH points_earned AS (
  SELECT 
    s.customer_id,
    SUM(
      CASE 
        WHEN s.order_date <= DATE_ADD(mem.join_date, INTERVAL 7 DAY) THEN m.price * 20  -- 2x multiplier for the first week
        ELSE m.price * 10  -- regular points
      END
    ) AS total_points
  FROM 
    sales s
  JOIN 
    menu m ON s.product_id = m.product_id
  JOIN 
    members mem ON s.customer_id = mem.customer_id
  WHERE 
    s.order_date <= '2021-01-31'  -- purchases in January
  GROUP BY 
    s.customer_id
)
SELECT 
  pe.customer_id,
  pe.total_points
FROM 
  points_earned pe
WHERE 
  pe.customer_id IN ('A', 'B');
