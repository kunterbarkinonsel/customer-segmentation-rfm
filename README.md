# Customer Segmentation with RFM (Snowflake SQL)

Segmenting nearly 100,000 customers by how recently, how often and how much they buy, so marketing knows who to reward, who to grow and who to win back. A retail business scenario built on Snowflake's TPC-H sample data.

## Business question

Leadership and the marketing team at a global retailer want to roll out new campaigns. They asked:

- Who are our high-value customers?
- How do customers differ in ordering behaviour?
- How should we segment customers so each group gets the right campaign?

## Data

Snowflake's public sample dataset `snowflake_sample_data.tpch_sf1`:

| Table | Rows | Used for |
|---|---|---|
| `customer` | 150,000 | Customer details |
| `orders` | 1,500,000 | Order dates |
| `lineitem` | 6,001,215 | Revenue per order |
| `nation` | 25 | Country names |

99,996 customers have at least one order and are included in the analysis. The data is from the 1990s, so the latest order date in the dataset is treated as "today".

## Approach

1. Calculate revenue per order from line items: `extended price × (1 − discount)`.
2. Build one row per customer: last order date, number of orders, total revenue, average order value.
3. Score each customer 1–5 on **R**ecency, **F**requency and **M**onetary value with `NTILE(5)`. A score of 5 is always the best group.
4. Add the three scores into an RFM score (3–15) and label the customer:

| Segment | RFM score |
|---|---|
| HIGH | 13–15 |
| MEDIUM | 9–12 |
| LOW | 3–8 |

## Key results

| Segment | Customers | Share of customers | Share of revenue | Avg. orders | Avg. days since last order |
|---|---|---|---|---|---|
| HIGH | 20,202 | 20% | 32% | 23.2 | 47 |
| MEDIUM | 34,744 | 35% | 40% | 17.2 | 119 |
| LOW | 45,050 | 45% | 28% | 9.6 | 286 |

- **The top 20% of customers bring in 32% of revenue.** They order more than twice as often as the LOW segment.
- **The MEDIUM segment is the biggest revenue source (40%)** and the best growth opportunity: these customers buy regularly but not recently.
- **13,334 customers have not ordered in over a year.** 1,043 of them still score MEDIUM because of strong past frequency and spend, which makes them the first group to target for win-back.
- High-value customers are spread evenly across countries (China, India, Jordan and the United States lead by a small margin), so campaigns should target behaviour rather than geography.

## Recommendations

1. **Protect the HIGH segment** with loyalty benefits or priority support. Losing one of these customers costs 2.5× the revenue of a LOW customer.
2. **Grow the MEDIUM segment** with reminders and targeted offers that bring them back sooner.
3. **Win back lapsed customers**, starting with the 1,043 inactive customers who used to be frequent, high-spending buyers.
4. **Re-engage the LOW segment cheaply** with low-cost channels such as email and limited-time discounts.

## SQL techniques used

- CTEs to build the analysis in readable steps
- Window functions (`NTILE`) for scoring
- `INNER`, `LEFT` and `CROSS` joins, each chosen for a reason explained in the code comments
- Aggregations, `DATEDIFF` and `CASE` logic

## Files

| File | What it does |
|---|---|
| `01_rfm_segmentation.sql` | Full segmentation query, one row per customer |
| `02_segment_analysis.sql` | Follow-up queries: segment sizes, revenue, top customers, nations, win-back list |

## How to run

1. Open a worksheet in Snowflake (a free trial account includes the sample data).
2. Paste `01_rfm_segmentation.sql` and run it.
3. To run a follow-up query, replace the last `SELECT` with one from `02_segment_analysis.sql`.

## Next steps

- Market-basket analysis to see which products each segment buys together
- Seasonality: order volume by month to time campaigns
- Churn modelling to flag at-risk customers before they go inactive

---

Built as the final assessment for the *Databases & SQL Fundamentals* course in the Data Analyst Programme at Hyper Island.
