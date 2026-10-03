-- Сначала показываем исходные знаки и справочник, не угадываем бухгалтерскую семантику.
SELECT t.type_id,tt.description,count(*) AS operations,
       min(t.value) AS min_value,max(t.value) AS max_value,sum(t.value) AS raw_sum
FROM "transaction" t JOIN cu u ON u.id=t.user_id
LEFT JOIN transactiontype tt ON tt.type=t.type_id CROSS JOIN params p
WHERE t.created_at>=greatest(p.start_at,u.date_joined) AND t.created_at<p.end_at
GROUP BY t.type_id,tt.description ORDER BY t.type_id;
