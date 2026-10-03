"""Reproduce PostgreSQL calculations on the downloaded anonymized course snapshot.

Only temporary tables/views are created; the connection is rolled back on exit.
"""
import csv
import json
import os
from pathlib import Path
from decimal import Decimal
from datetime import date, datetime
import psycopg2
from psycopg2.extras import execute_values
from psycopg2 import sql

ROOT = Path(__file__).resolve().parent
csv.field_size_limit(100_000_000)

def encode(x):
    if isinstance(x, Decimal): return float(x)
    if isinstance(x, (date, datetime)): return x.isoformat()
    raise TypeError(type(x).__name__)

def main():
    data = {r['dataset']: json.loads(r['data']) for r in csv.DictReader(
        (ROOT/'source/company1-export.csv').open(encoding='utf-8-sig'))}
    types = {(r['table_name'],r['column_name']):r['data_type'] for r in csv.DictReader(
        (ROOT/'source/schema.csv').open(encoding='utf-8-sig'))}
    results = {}
    conn = psycopg2.connect(host=os.getenv('PGHOST','127.0.0.1'),
        port=os.getenv('PGPORT','55439'),user=os.getenv('PGUSER','postgres'),
        dbname=os.getenv('PGDATABASE','postgres'))
    try:
        with conn.cursor() as cur:
            cur.execute("SET statement_timeout = '60s'")
            for table,rows in data.items():
                if table=='coverage': continue
                cols=list(rows[0])
                definitions=sql.SQL(',').join(sql.SQL('{} {}').format(
                    sql.Identifier(k),sql.SQL(types[table,k])) for k in cols)
                cur.execute(sql.SQL('CREATE TEMP TABLE {} ({})').format(sql.Identifier(table),definitions))
                execute_values(cur,sql.SQL('INSERT INTO {} VALUES %s').format(sql.Identifier(table)),
                    [[r[k] for k in cols] for r in rows])
            cur.execute((ROOT/'sql/00_prepare.sql').read_text(encoding='utf-8'))
            for path in sorted((ROOT/'sql').glob('*.sql')):
                if path.name.startswith('00_'): continue
                cur.execute(path.read_text(encoding='utf-8'))
                cols=[c.name for c in cur.description]
                rows=[dict(zip(cols,r)) for r in cur.fetchall()]
                results[path.stem]=rows
                out=ROOT/'results'/f'{path.stem}.csv'
                out.parent.mkdir(exist_ok=True)
                with out.open('w',encoding='utf-8-sig',newline='') as f:
                    writer=csv.DictWriter(f,fieldnames=cols);writer.writeheader();writer.writerows(rows)
            for path in sorted((ROOT/'metabase').glob('*.sql')):
                cur.execute(path.read_text(encoding='utf-8'))
                cols=[c.name for c in cur.description]
                rows=[dict(zip(cols,r)) for r in cur.fetchall()]
                assert rows == results[path.stem], path.name
            (ROOT/'results/all.json').write_text(json.dumps(results,ensure_ascii=False,indent=2,default=encode),encoding='utf-8')
            print('12 SQL queries and 12 standalone Metabase variants passed.')
    finally:
        conn.rollback();conn.close()

if __name__=='__main__': main()
