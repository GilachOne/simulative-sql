WITH first_action AS (
    SELECT user_id, min(created_at) AS first_at FROM submits GROUP BY user_id
), windows AS (SELECT unnest(ARRAY[7,14]) AS days)
SELECT w.days, count(*) AS eligible,
       count(*) FILTER (WHERE f.first_at < u.date_joined + w.days * INTERVAL '1 day') AS activated,
       round(100.0 * count(*) FILTER (WHERE f.first_at < u.date_joined + w.days * INTERVAL '1 day') / nullif(count(*),0),2) AS activation_pct
FROM cu u CROSS JOIN params p CROSS JOIN windows w
LEFT JOIN first_action f ON f.user_id = u.id
WHERE u.date_joined >= p.start_at
  AND u.date_joined + w.days * INTERVAL '1 day' <= p.end_at
GROUP BY w.days ORDER BY w.days;
