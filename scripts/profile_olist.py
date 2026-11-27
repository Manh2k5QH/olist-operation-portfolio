"""Rebuild evidence from governed DuckDB SQL without changing presentation files."""
import argparse
import csv
import json
import os
import hashlib
import platform
from datetime import datetime, timezone
from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parents[1]


def file_sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def export(db, output, name, query):
    result = db.execute(query)
    target = output / name
    temporary = target.with_suffix(target.suffix + '.tmp')
    with temporary.open('w', encoding='utf-8', newline='') as stream:
        writer = csv.writer(stream)
        writer.writerow([column[0] for column in result.description])
        writer.writerows(result.fetchall())
    temporary.replace(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'evidence')
    parser.add_argument('--skip-delivery-export', action='store_true',
                        help='Retain the existing large delivery export, for statistical evidence-only refreshes.')
    arguments = parser.parse_args()
    output = arguments.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    os.chdir(ROOT)
    db = duckdb.connect()
    for path in sorted((ROOT / 'sql/views').glob('*.sql')):
        db.execute(path.read_text(encoding='utf-8'))
    def scalar(query):
        return db.execute(query).fetchone()[0]
    queries = {
        'orders': 'SELECT COUNT(*) FROM stg_orders',
        'delivered_orders': "SELECT COUNT(*) FROM stg_orders WHERE order_status='delivered'",
        'delivered_orders_with_dates': 'SELECT COUNT(*) FROM mart_order_delivery',
        'late_orders': 'SELECT COUNT(*) FROM mart_order_delivery WHERE is_late',
        'late_rate': 'SELECT AVG(is_late::INT) FROM mart_order_delivery',
        'avg_late_days': 'SELECT AVG(delay_days) FROM mart_order_delivery WHERE is_late',
        'avg_late_elapsed_days': 'SELECT AVG(delay_elapsed_days) FROM mart_order_delivery WHERE is_late',
        'on_time_review': 'SELECT AVG(review_score) FROM mart_order_delivery WHERE NOT is_late',
        'late_review': 'SELECT AVG(review_score) FROM mart_order_delivery WHERE is_late',
        'on_time_reviewed_orders': 'SELECT COUNT(review_score) FROM mart_order_delivery WHERE NOT is_late',
        'late_reviewed_orders': 'SELECT COUNT(review_score) FROM mart_order_delivery WHERE is_late',
        'gmv': 'SELECT ROUND(SUM(gmv),2) FROM mart_category',
        'freight': 'SELECT ROUND(SUM(freight_value),2) FROM mart_category',
        'delivery_eligible_gmv': 'SELECT ROUND(SUM(gmv),2) FROM mart_order_delivery',
        'late_order_gmv': 'SELECT ROUND(SUM(gmv),2) FROM mart_order_delivery WHERE is_late',
        'payment_total': "SELECT ROUND(SUM(payment_value),2) FROM read_csv_auto('data/olist_order_payments_dataset.csv')",
        'orders_with_items': "SELECT COUNT(DISTINCT order_id) FROM read_csv_auto('data/olist_order_items_dataset.csv')",
        'reviews': "SELECT COUNT(*) FROM read_csv_auto('data/olist_order_reviews_dataset.csv')",
        'orders_with_reviews': "SELECT COUNT(DISTINCT order_id) FROM read_csv_auto('data/olist_order_reviews_dataset.csv')",
        'avg_review': "SELECT AVG(review_score) FROM read_csv_auto('data/olist_order_reviews_dataset.csv')",
        'avg_review_order_weighted': "SELECT AVG(review_score) FROM (SELECT AVG(review_score) review_score FROM read_csv_auto('data/olist_order_reviews_dataset.csv') GROUP BY order_id)",
    }
    k = {name: scalar(query) for name, query in queries.items()}
    k['sla_definition'] = 'Delivered calendar date later than estimated calendar date'
    k['source_date_range'] = [str(v) for v in db.execute('SELECT MIN(purchased_at)::DATE, MAX(purchased_at)::DATE FROM stg_orders').fetchone()]
    unique, repeat = db.execute("""SELECT COUNT(*),COUNT(*) FILTER(WHERE n>1) FROM
        (SELECT customer_unique_id,COUNT(DISTINCT order_id) n FROM stg_orders
        JOIN read_csv_auto('data/olist_customers_dataset.csv') USING(customer_id) GROUP BY 1)""").fetchone()
    k.update(unique_customers=unique, repeat_buyers=repeat, repeat_rate=repeat/unique)
    k['repeat_population'] = 'All created orders in snapshot, including canceled; variable observation window'
    k['freight_share_of_gmv_plus_freight'] = k['freight'] / (k['gmv'] + k['freight'])
    k['payment_reconciliation_difference'] = round(k['payment_total'] - k['gmv'] - k['freight'], 2)
    k['aov_orders_with_items'] = k['gmv'] / k['orders_with_items']
    k['top_category'], k['top_category_gmv'] = db.execute('SELECT category,ROUND(gmv,2) FROM mart_category ORDER BY gmv DESC LIMIT 1').fetchone()
    k['join_note'] = 'Seller delivery metrics count each seller-order once. Multi-seller totals are non-additive.'
    state = """SELECT customer_state,COUNT(*) delivered_orders,SUM(is_late::INT) late_orders,
        AVG(is_late::INT) late_rate,AVG(review_score) avg_review,COUNT(review_score) reviewed_orders,
        SUM(gmv) gmv FROM mart_order_delivery GROUP BY 1"""
    result = db.execute(state + ' ORDER BY late_rate DESC LIMIT 1')
    k['top_state_late_rate'] = dict(zip([c[0] for c in result.description], result.fetchone()))
    # Preserve existing state column order and append uncertainty fields.
    uncertainty_path = ROOT / 'sql/analysis/06_delivery_uncertainty.sql'
    state_uncertainty = db.extract_statements(uncertainty_path.read_text(encoding='utf-8'))[0]
    db.execute('CREATE TEMP TABLE state_uncertainty AS ' + state_uncertainty.query)
    export(db,output,'state_kpis.csv',
           'SELECT s.*, u.late_rate_wilson95_lower, u.late_rate_wilson95_upper, u.sample_flag '
           'FROM (' + state + ') s JOIN state_uncertainty u USING(customer_state) '
           'ORDER BY delivered_orders DESC')
    export(db,output,'category_kpis.csv','SELECT category,item_rows AS items,gmv,freight_value AS freight,freight_share AS freight_rate FROM mart_category ORDER BY gmv DESC')
    export(db,output,'seller_kpis.csv','SELECT *, item_rows AS items,total_orders AS orders FROM mart_seller ORDER BY gmv DESC')
    if not arguments.skip_delivery_export:
        export(db,output,'delivered_order_mart.csv','SELECT *, purchased_at AS order_purchase_timestamp, delivered_at AS order_delivered_customer_date, estimated_at AS order_estimated_delivery_date,freight_value AS freight FROM mart_order_delivery')
    export(db,output,'review_coverage.csv','SELECT is_late,COUNT(*) eligible_orders,COUNT(review_score) reviewed_orders,AVG(review_score) avg_review FROM mart_order_delivery GROUP BY 1')
    for path in sorted((ROOT / 'sql/analysis').glob('*.sql')):
        for index, statement in enumerate(db.extract_statements(path.read_text(encoding='utf-8')),1):
            export(db,output,f'{path.stem}_q{index:02}.csv',statement)
            if path.name == '04_revenue_category.sql' and index == 1:
                export(db,output,'monthly_kpis.csv',statement)
    profile = [(p.name,db.execute('SELECT COUNT(*) FROM read_csv_auto(?)',[str(p)]).fetchone()[0]) for p in sorted((ROOT/'data').glob('*.csv'))]
    k['source_row_count'] = sum(row[1] for row in profile)
    with (output/'data_quality_profile.csv').open('w',encoding='utf-8',newline='') as stream:
        writer=csv.writer(stream)
        writer.writerow(['file','rows'])
        writer.writerows(profile)
    (output/'kpis.json').write_text(json.dumps(k,ensure_ascii=False,indent=2),encoding='utf-8')
    source_files = []
    for name, rows in profile:
        path = ROOT / 'data' / name
        source_files.append({'path': 'data/' + name, 'rows': rows,
                             'bytes': path.stat().st_size,
                             'sha256': file_sha256(path)})
    code_files = [Path(__file__).resolve(), *sorted((ROOT/'sql').glob('*/*.sql'))]
    manifest = {
        'generated_at_utc': datetime.now(timezone.utc).isoformat(),
        'python_version': platform.python_version(), 'duckdb_version': duckdb.__version__,
        'sla_definition': k['sla_definition'], 'source_files': source_files,
        'code_files': [{'path': str(path.relative_to(ROOT)).replace('\\', '/'),
                        'sha256': file_sha256(path)} for path in code_files],
        'delivery_export_refreshed': not arguments.skip_delivery_export,
        'analysis_query_count': sum(len(db.extract_statements(path.read_text(encoding='utf-8')))
                                    for path in (ROOT/'sql/analysis').glob('*.sql')),
    }
    (output/'reproducibility_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    db.close()
    print(json.dumps(k,ensure_ascii=False,indent=2))


if __name__ == '__main__':
    main()
