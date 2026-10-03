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
attempts AS (
 SELECT s.problem_id, count(*) AS attempts,
        count(*) FILTER (WHERE is_false=1) AS failed,
        count(DISTINCT user_id) AS students,
        count(DISTINCT user_id) FILTER (WHERE is_false=0) AS solvers
 FROM submits s CROSS JOIN params p
 WHERE s.created_at >= p.start_at AND s.is_false IN (0,1)
 GROUP BY s.problem_id
), costs AS (
 SELECT f.problem_id, f.user_id, count(*) AS attempts_to_success
 FROM first_success f JOIN submits s ON s.user_id=f.user_id AND s.problem_id=f.problem_id
    AND (s.created_at,s.id) <= (f.solved_at,f.submit_id)
 CROSS JOIN params p WHERE f.solved_at >= p.start_at
 GROUP BY f.problem_id,f.user_id
), quantiles AS (
 SELECT problem_id, percentile_cont(0.5) WITHIN GROUP (ORDER BY attempts_to_success) AS median_attempts,
        percentile_cont(0.9) WITHIN GROUP (ORDER BY attempts_to_success) AS p90_attempts
 FROM costs GROUP BY problem_id
)
SELECT a.problem_id, p.name, p.complexity, a.students, a.solvers, a.attempts, a.failed,
       round(100.0*a.failed/nullif(a.attempts,0),2) AS error_pct,
       q.median_attempts, q.p90_attempts
FROM attempts a JOIN problem p ON p.id=a.problem_id
LEFT JOIN quantiles q ON q.problem_id=a.problem_id
WHERE a.attempts>=20 AND a.students>=5
ORDER BY error_pct DESC, a.attempts DESC, a.problem_id;