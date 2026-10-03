WITH attempts AS (
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
