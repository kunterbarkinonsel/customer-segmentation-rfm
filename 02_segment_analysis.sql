-- Segment analysis queries
-- Each query below replaces the last SELECT in 01_rfm_segmentation.sql
-- (everything after the "final" CTE).

-- 1. How many customers fall into each segment?
SELECT
    rfm_segment,
    COUNT(*) AS customer_count
FROM final
GROUP BY rfm_segment
ORDER BY customer_count DESC;

-- 2. How much revenue does each segment generate?
SELECT
    rfm_segment,
    SUM(total_revenue) AS segment_total_revenue
FROM final
GROUP BY rfm_segment
ORDER BY segment_total_revenue DESC;

-- 3. Who are the top 5 high-value customers by RFM score?
--    Many customers share the top score of 15, so revenue breaks the tie.
SELECT
    customer_id,
    customer_name,
    nation_name,
    rfm_score,
    r_score,
    f_score,
    m_score,
    total_revenue,
    total_orders,
    recency_days
FROM final
ORDER BY rfm_score DESC, total_revenue DESC
LIMIT 5;

-- 4. Which nations have the most high-value customers?
SELECT
    nation_name,
    COUNT(*) AS high_value_customer_count
FROM final
WHERE rfm_segment = 'HIGH'
GROUP BY nation_name
ORDER BY high_value_customer_count DESC;

-- 5. Win-back list: customers with no order in the last 365 days,
--    best former customers first.
SELECT *
FROM final
WHERE recency_days >= 365
ORDER BY rfm_score DESC, total_revenue DESC;
