SELECT h.problem_id,p.name,p.complexity
FROM homework h JOIN problem p ON p.id=h.problem_id
CROSS JOIN params x
WHERE NOT EXISTS (
 SELECT 1 FROM practice a WHERE a.problem_id=h.problem_id AND a.created_at>=x.start_at
)
ORDER BY p.complexity DESC,h.problem_id;
