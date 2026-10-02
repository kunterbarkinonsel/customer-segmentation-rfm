-- Customer Segmentation with RFM
-- Author: Kunter Barkin Önsel
-- Platform: Snowflake (dataset: snowflake_sample_data.tpch_sf1)
--
-- Output: one row per customer with Recency, Frequency and Monetary scores (1-5),
-- a total RFM score (3-15) and a segment label (HIGH / MEDIUM / LOW).

-- Revenue per order = extended price * (1 - discount), summed over the order's line items.
-- I need this to calculate monetary value at the customer level later.
WITH order_revenue AS (
    SELECT
        l_orderkey AS order_id,
        ROUND(SUM(l_extendedprice * (1 - l_discount)), 0) AS order_total
    FROM snowflake_sample_data.tpch_sf1.lineitem
    GROUP BY l_orderkey
),

-- Attach revenue to each order. INNER JOIN because I only want orders
-- that actually have line items and revenue.
orders_with_revenue AS (
    SELECT
        o.o_orderkey  AS order_id,
        o.o_custkey   AS customer_id,
        o.o_orderdate AS order_date,
        orr.order_total
    FROM snowflake_sample_data.tpch_sf1.orders o
    INNER JOIN order_revenue orr
        ON o.o_orderkey = orr.order_id
),

-- One row per customer with the raw RFM inputs.
-- INNER JOIN drops customers who never ordered: they have no recency,
-- frequency or monetary value to score.
customer_metrics AS (
    SELECT
        c.c_custkey                   AS customer_id,
        c.c_name                      AS customer_name,
        c.c_nationkey                 AS nation_key,
        MAX(owr.order_date)           AS last_order_date,
        COUNT(DISTINCT owr.order_id)  AS total_orders,
        ROUND(SUM(owr.order_total), 0) AS total_revenue,
        ROUND(AVG(owr.order_total), 0) AS avg_order_value
    FROM snowflake_sample_data.tpch_sf1.customer c
    INNER JOIN orders_with_revenue owr
        ON c.c_custkey = owr.customer_id
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),

-- The data is from the 1990s, so I treat the latest order date in the
-- dataset as "today" instead of using the real current date.
recency_reference AS (
    SELECT MAX(order_date) AS max_order_date
    FROM orders_with_revenue
),

-- NTILE(5) splits customers into 5 equal groups. Group 5 is always the best:
--   R: fewest days since last order  -> sort recency_days DESC so the most recent land in group 5
--   F: most orders                   -> sort total_orders ASC so the most frequent land in group 5
--   M: highest revenue               -> sort total_revenue ASC so the biggest spenders land in group 5
-- customer_id is a tie-breaker so the query returns the same result on every run.
-- CROSS JOIN adds the single reference date to every customer row (there is no key to join on).
rfm_scored AS (
    SELECT
        cm.*,
        DATEDIFF(day, cm.last_order_date, rr.max_order_date) AS recency_days,
        NTILE(5) OVER (
            ORDER BY DATEDIFF(day, cm.last_order_date, rr.max_order_date) DESC, cm.customer_id
        ) AS r_score,
        NTILE(5) OVER (ORDER BY cm.total_orders,  cm.customer_id) AS f_score,
        NTILE(5) OVER (ORDER BY cm.total_revenue, cm.customer_id) AS m_score
    FROM customer_metrics cm
    CROSS JOIN recency_reference rr
),

-- Add the three scores together (3-15) and label each customer.
rfm_segmented AS (
    SELECT
        r.*,
        r.r_score + r.f_score + r.m_score AS rfm_score,
        CASE
            WHEN r.r_score + r.f_score + r.m_score >= 13 THEN 'HIGH'
            WHEN r.r_score + r.f_score + r.m_score >= 9  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS rfm_segment
    FROM rfm_scored r
),

-- Add the nation name. LEFT JOIN so no customer is lost if a nation key has no match.
final AS (
    SELECT
        seg.customer_id,
        seg.customer_name,
        n.n_name AS nation_name,
        seg.last_order_date,
        seg.total_revenue,
        seg.total_orders,
        seg.avg_order_value,
        seg.recency_days,
        seg.r_score,
        seg.f_score,
        seg.m_score,
        seg.rfm_score,
        seg.rfm_segment
    FROM rfm_segmented seg
    LEFT JOIN snowflake_sample_data.tpch_sf1.nation n
        ON seg.nation_key = n.n_nationkey
)

SELECT *
FROM final
ORDER BY rfm_score DESC, total_revenue DESC;
