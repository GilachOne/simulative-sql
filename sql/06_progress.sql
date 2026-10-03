WITH counts AS (
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
