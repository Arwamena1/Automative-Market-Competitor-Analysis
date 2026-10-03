"""Run with Python 3: python run_analysis.py. No extra packages needed."""
import csv, pathlib, sqlite3, re
ROOT=pathlib.Path(__file__).resolve().parent
conn=sqlite3.connect(ROOT/'automotive_2025.sqlite')
conn.execute('DROP VIEW IF EXISTS selected_models')
conn.execute('DROP TABLE IF EXISTS registrations')
conn.execute('CREATE TABLE registrations (year INTEGER, month_number INTEGER, month_name TEXT, month_start TEXT, segment TEXT, brand TEXT, model TEXT, registrations INTEGER, source_object_id INTEGER)')
with open(ROOT/'data/registrations_2025_clean.csv',encoding='utf-8-sig',newline='') as f:
    reader=csv.DictReader(f)
    rows=[(int(r['year']),int(r['month_number']),r['month_name'],r['month_start'],r['segment'],r['brand'],r['model'],int(r['registrations']),int(r['source_object_id'])) for r in reader]
conn.executemany('INSERT INTO registrations VALUES (?,?,?,?,?,?,?,?,?)',rows)
sql=(ROOT/'sql/analysis.sql').read_text(encoding='utf-8')
setup=sql.split('-- name: model_totals')[0]
conn.executescript(setup)
(ROOT/'results').mkdir(exist_ok=True)
for match in re.finditer(r'-- name: (\w+)\n(.*?)(?=-- name: |\Z)',sql,re.S):
    name,query=match.groups();cur=conn.execute(query)
    result=cur.fetchall()
    with open(ROOT/'results'/f'{name}.csv','w',encoding='utf-8-sig',newline='') as f:
        writer=csv.writer(f);writer.writerow([c[0] for c in cur.description]);writer.writerows(result)
    print(f'{name}: {len(result)} result rows')
conn.commit();conn.close()
