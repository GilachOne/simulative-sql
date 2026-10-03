SELECT 'users' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."company_id",t."date_joined" FROM "users" t WHERE t.company_id=1) s
UNION ALL
SELECT 'coderun' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."user_id",t."created_at",t."problem_id" FROM "coderun" t JOIN users u ON u.id=t.user_id WHERE u.company_id=1) s
UNION ALL
SELECT 'codesubmit' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."user_id",t."is_false",t."created_at",t."problem_id" FROM "codesubmit" t JOIN users u ON u.id=t.user_id WHERE u.company_id=1) s
UNION ALL
SELECT 'userentry' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."user_id",t."entry_at" FROM "userentry" t JOIN users u ON u.id=t.user_id WHERE u.company_id=1) s
UNION ALL
SELECT 'problem' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."name",t."complexity" FROM "problem" t) s
UNION ALL
SELECT 'problem_to_company' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."name",t."company_id",t."problem_id" FROM "problem_to_company" t WHERE t.company_id=1) s
UNION ALL
SELECT 'transaction' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."id",t."value",t."type_id",t."user_id",t."created_at" FROM "transaction" t JOIN users u ON u.id=t.user_id WHERE u.company_id=1) s
UNION ALL
SELECT 'transactiontype' AS dataset, COALESCE(jsonb_agg(to_jsonb(s)), '[]')::text AS data FROM (SELECT t."type",t."value",t."description" FROM "transactiontype" t) s
UNION ALL
SELECT 'coverage', jsonb_build_object('run_max',(SELECT max(created_at) FROM coderun),'submit_max',(SELECT max(created_at) FROM codesubmit),'entry_max',(SELECT max(entry_at) FROM userentry))::text;
