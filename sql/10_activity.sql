-- Время сохранено как timestamp without time zone: часовой пояс неизвестен.
SELECT extract(isodow FROM created_at)::integer AS weekday,
       extract(hour FROM created_at)::integer AS hour,
       count(*) AS runs, count(DISTINCT user_id) AS students
FROM runs CROSS JOIN params WHERE created_at>=start_at
GROUP BY 1,2 ORDER BY 1,2;
