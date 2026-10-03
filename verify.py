"""Independent checks of the SQL results using Python sets and dates."""
import csv,json
from collections import Counter
from datetime import datetime,timedelta
from pathlib import Path
from math import sqrt
P=Path(__file__).resolve().parent
csv.field_size_limit(100000000)
d={r['dataset']:json.loads(r['data']) for r in csv.DictReader((P/'source/company1-export.csv').open(encoding='utf-8-sig'))}
r=json.loads((P/'results/all.json').read_text(encoding='utf-8'))
start=datetime(2021,7,1); end=datetime(2022,5,1)
users={x['id']:datetime.fromisoformat(x['date_joined']) for x in d['users']}
def events(table,key):
 return [dict(x,dt=datetime.fromisoformat(x[key])) for x in d[table]
         if users[x['user_id']] <= datetime.fromisoformat(x[key]) < end]
runs=events('coderun','created_at');subs=events('codesubmit','created_at');visits=events('userentry','entry_at')
first={}
for x in sorted(subs,key=lambda x:(x['dt'],x['id'])):
 if x['is_false']==0:first.setdefault((x['user_id'],x['problem_id']),x)
checks=[]
def eq(name,a,b):
 assert a==b,(name,a,b)
 checks.append(name)
k=r['02_kpi'][0]
eq('users',len(users),k['students'])
for key,ev in [('visitors',visits),('coders',runs),('submitters',subs)]:
 eq(key,len({x['user_id'] for x in ev if x['dt']>=start}),k[key])
eq('new solutions',len(first),k['new_user_problem_solutions'])
eq('success submissions',sum(x['is_false']==0 for x in subs),k['successful_submissions'])
for row in r['03_monthly']:
 m=datetime.fromisoformat(row['month']);n=(m.replace(day=28)+timedelta(days=4)).replace(day=1)
 eq('monthly solutions '+row['month'],sum(m<=x['dt']<n for x in first.values()),row['new_solutions'])
 eq('monthly active '+row['month'],len({x['user_id'] for x in runs+subs if m<=x['dt']<n}),row['active_students'])
for row in r['04_activation']:
 days=row['days']; eligible={u:t for u,t in users.items() if t+timedelta(days=days)<=end}
 active={x['user_id'] for x in subs if x['user_id'] in eligible and x['dt']<eligible[x['user_id']]+timedelta(days=days)}
 eq('activation denominator '+str(days),len(eligible),row['eligible'])
 eq('activation numerator '+str(days),len(active),row['activated'])
for row in r['09_retention']:
 c=datetime.fromisoformat(row['cohort']);n=row['month_number'];idx=c.year*12+c.month-1+n
 m=datetime(idx//12,idx%12+1,1);idx+=1;stop=datetime(idx//12,idx%12+1,1)
 cohort={u for u,t in users.items() if (t.year,t.month)==(c.year,c.month)}
 val=None if stop>end else len({x['user_id'] for x in runs+subs if x['user_id'] in cohort and m<=x['dt']<stop})
 eq('retention '+row['cohort']+' M'+str(n),val,row['active_students'])
hw={x['problem_id'] for x in d['problem_to_company']}
attempted={(x['user_id'],x['problem_id']) for x in runs+subs if x['problem_id'] in hw}
solved={pair for pair in first if pair[1] in hw}
eq('homework pairs',len(attempted),r['08_homework'][0]['attempted_pairs'])
eq('homework solved pairs',len(solved),r['08_homework'][0]['solved_pairs'])
eq('bucket population',sum(x['students'] for x in r['06_progress']),len(users))
eq('monthly total',sum(x['new_solutions'] for x in r['03_monthly']),k['new_user_problem_solutions'])
eq('heatmap total',sum(x['runs'] for x in r['10_activity']),k['runs'])
# Descriptive normal approximation, not a causal estimate.
a,b=r['05_activation_return'];p1=a['returned']/a['students'];p0=b['returned']/b['students']
se=sqrt(p1*(1-p1)/a['students']+p0*(1-p0)/b['students'])
result={'checks_passed':len(checks),'checks':checks,'return_difference_pp':100*(p1-p0),
 'approximate_95_ci_pp':[100*(p1-p0-1.96*se),100*(p1-p0+1.96*se)]}
(P/'results/verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='checks'}))
