WITH months AS (
    SELECT generate_series(date_trunc('month', start_at),
           end_at - INTERVAL '1 month', INTERVAL '1 month') AS month FROM params
)
SELECT m.month::date,
       (SELECT count(*) FROM cu WHERE date_joined < m.month + INTERVAL '1 month') AS students_to_date,
       (SELECT count(DISTINCT user_id) FROM visits WHERE entry_at >= m.month AND entry_at < m.month + INTERVAL '1 month') AS visitors,
       (SELECT count(DISTINCT user_id) FROM practice WHERE created_at >= m.month AND created_at < m.month + INTERVAL '1 month') AS active_students,
       (SELECT count(*) FROM runs WHERE created_at >= m.month AND created_at < m.month + INTERVAL '1 month') AS runs,
       (SELECT count(*) FROM submits WHERE created_at >= m.month AND created_at < m.month + INTERVAL '1 month') AS submissions,
       (SELECT count(*) FROM first_success WHERE solved_at >= m.month AND solved_at < m.month + INTERVAL '1 month') AS new_solutions
FROM months m ORDER BY m.month;
