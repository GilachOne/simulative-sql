WITH params AS (
SELECT 1::integer AS company_id,
       TIMESTAMP '2021-07-01' AS start_at,
       TIMESTAMP '2022-05-01' AS end_at
),
cu AS (
SELECT u.id, u.date_joined
FROM users u CROSS JOIN params p
WHERE u.company_id = p.company_id AND u.date_joined < p.end_at
),
runs AS (
SELECT r.id, r.user_id, r.problem_id, r.created_at
FROM coderun r JOIN cu u ON u.id = r.user_id CROSS JOIN params p
WHERE r.created_at >= u.date_joined AND r.created_at < p.end_at
),
submits AS (
SELECT s.id, s.user_id, s.problem_id, s.created_at, s.is_false
FROM codesubmit s JOIN cu u ON u.id = s.user_id CROSS JOIN params p
WHERE s.created_at >= u.date_joined AND s.created_at < p.end_at
),
visits AS (
SELECT e.id, e.user_id, e.entry_at
FROM userentry e JOIN cu u ON u.id = e.user_id CROSS JOIN params p
WHERE e.entry_at >= u.date_joined AND e.entry_at < p.end_at
),
first_success AS (
SELECT DISTINCT ON (user_id, problem_id)
       user_id, problem_id, created_at AS solved_at, id AS submit_id
FROM submits
WHERE is_false = 0
ORDER BY user_id, problem_id, created_at, id
),
homework AS (
SELECT DISTINCT pc.problem_id
FROM problem_to_company pc CROSS JOIN params p
WHERE pc.company_id = p.company_id
),
practice AS (
SELECT user_id, problem_id, created_at FROM runs
UNION
SELECT user_id, problem_id, created_at FROM submits
),
cohorts AS (
 SELECT id, date_trunc('month',date_joined) AS cohort FROM cu CROSS JOIN params
 WHERE date_joined>=start_at
), sizes AS (SELECT cohort,count(*) AS n FROM cohorts GROUP BY cohort),
grid AS (
 SELECT c.cohort,c.n,x.k, c.cohort + x.k * INTERVAL '1 month' AS month
 FROM sizes c CROSS JOIN generate_series(0,9) x(k)
)
SELECT g.cohort::date,g.k AS month_number,g.n AS cohort_size,
       CASE WHEN g.month+INTERVAL '1 month'<=p.end_at THEN (
         SELECT count(DISTINCT a.user_id) FROM practice a JOIN cohorts c ON c.id=a.user_id
         WHERE c.cohort=g.cohort AND a.created_at>=g.month AND a.created_at<g.month+INTERVAL '1 month'
       ) END AS active_students,
       CASE WHEN g.month+INTERVAL '1 month'<=p.end_at THEN round(100.0*(
         SELECT count(DISTINCT a.user_id) FROM practice a JOIN cohorts c ON c.id=a.user_id
         WHERE c.cohort=g.cohort AND a.created_at>=g.month AND a.created_at<g.month+INTERVAL '1 month'
       )/g.n,2) END AS retention_pct
FROM grid g CROSS JOIN params p ORDER BY g.cohort,g.k;