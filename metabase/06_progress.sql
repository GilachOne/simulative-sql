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
counts AS (
 SELECT u.id, count(f.problem_id) AS solved
 FROM cu u CROSS JOIN params p
 LEFT JOIN first_success f ON f.user_id=u.id AND f.solved_at >= p.start_at
 GROUP BY u.id
), buckets AS (
 SELECT CASE WHEN solved=0 THEN 0 WHEN solved<=2 THEN 1 WHEN solved<=5 THEN 2 WHEN solved<=10 THEN 3 ELSE 4 END AS bucket
 FROM counts
)
SELECT b.label, count(x.bucket) AS students
FROM (VALUES (0,'0'),(1,'1–2'),(2,'3–5'),(3,'6–10'),(4,'11+')) b(ord,label)
LEFT JOIN buckets x ON x.bucket=b.ord
GROUP BY b.ord,b.label ORDER BY b.ord;