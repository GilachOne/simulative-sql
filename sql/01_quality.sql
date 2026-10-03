SELECT 'users' AS dataset, count(*) AS rows_count,
       count(*) - count(DISTINCT u.id) AS duplicate_ids,
       min(u.date_joined) AS first_at, max(u.date_joined) AS last_at,
       count(*) FILTER (WHERE u.date_joined IS NULL) AS null_dates,
       0::bigint AS before_registration
FROM users u CROSS JOIN params p WHERE u.company_id = p.company_id
UNION ALL
SELECT 'coderun', count(*), count(*) - count(DISTINCT r.id),
       min(r.created_at), max(r.created_at),
       count(*) FILTER (WHERE r.created_at IS NULL),
       count(*) FILTER (WHERE r.created_at < u.date_joined)
FROM coderun r JOIN cu u ON u.id = r.user_id
UNION ALL
SELECT 'codesubmit', count(*), count(*) - count(DISTINCT s.id),
       min(s.created_at), max(s.created_at),
       count(*) FILTER (WHERE s.created_at IS NULL),
       count(*) FILTER (WHERE s.created_at < u.date_joined)
FROM codesubmit s JOIN cu u ON u.id = s.user_id
UNION ALL
SELECT 'userentry', count(*), count(*) - count(DISTINCT e.id),
       min(e.entry_at), max(e.entry_at),
       count(*) FILTER (WHERE e.entry_at IS NULL),
       count(*) FILTER (WHERE e.entry_at < u.date_joined)
FROM userentry e JOIN cu u ON u.id = e.user_id;
