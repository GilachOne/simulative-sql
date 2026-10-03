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
attempted AS (
 SELECT DISTINCT a.user_id,a.problem_id FROM practice a JOIN homework h USING(problem_id)
 CROSS JOIN params p WHERE a.created_at>=p.start_at
), solved AS (
 SELECT f.* FROM first_success f JOIN homework h USING(problem_id)
 CROSS JOIN params p WHERE f.solved_at>=p.start_at
)
SELECT (SELECT count(*) FROM homework) AS assigned_tasks,
       (SELECT count(DISTINCT problem_id) FROM attempted) AS attempted_tasks,
       (SELECT count(DISTINCT problem_id) FROM solved) AS solved_tasks,
       (SELECT count(*) FROM homework)*(SELECT count(*) FROM cu) AS potential_student_task_pairs,
       (SELECT count(*) FROM attempted) AS attempted_pairs,
       (SELECT count(*) FROM solved) AS solved_pairs,
       (SELECT count(DISTINCT user_id) FROM attempted) AS attempting_students,
       (SELECT count(DISTINCT user_id) FROM solved) AS solving_students;