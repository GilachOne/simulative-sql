WITH attempted AS (
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
