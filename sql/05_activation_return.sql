-- Гипотеза о связи ранней сдачи с последующей практикой.
-- Для всех пользователей одинаковый срок наблюдения 60 дней.
WITH flags AS (
 SELECT u.id,
        EXISTS (SELECT 1 FROM submits s WHERE s.user_id=u.id AND s.created_at < u.date_joined + INTERVAL '7 days') AS early,
        EXISTS (SELECT 1 FROM practice a WHERE a.user_id=u.id AND a.created_at >= u.date_joined + INTERVAL '30 days' AND a.created_at < u.date_joined + INTERVAL '60 days') AS returned
 FROM cu u CROSS JOIN params p
 WHERE u.date_joined >= p.start_at AND u.date_joined + INTERVAL '60 days' <= p.end_at
)
SELECT early, count(*) AS students, count(*) FILTER (WHERE returned) AS returned,
       round(100.0 * count(*) FILTER (WHERE returned) / nullif(count(*),0),2) AS return_pct
FROM flags GROUP BY early ORDER BY early DESC;
