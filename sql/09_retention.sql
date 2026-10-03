WITH cohorts AS (
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
