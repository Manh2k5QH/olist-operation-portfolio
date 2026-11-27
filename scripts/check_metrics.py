"""Regression checks for date-based delivery SLA and seller-order grain."""
from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parents[1]


def check_sla_boundaries():
    connection = duckdb.connect()
    raw = """(SELECT * FROM (VALUES
        ('same_day','delivered','2018-01-01 23:59:00','2018-01-01 00:00:00'),
        ('next_day','delivered','2018-01-02 00:01:00','2018-01-01 00:00:00'),
        ('missing','delivered',NULL,'2018-01-01 00:00:00'),
        ('no_estimate','delivered','2018-01-02 00:01:00',NULL),
        ('canceled','canceled','2018-01-02 00:01:00','2018-01-01 00:00:00')
        ) t(order_id,order_status,order_delivered_customer_date,order_estimated_delivery_date)
        CROSS JOIN (SELECT 'customer' customer_id,
            '2017-12-30' order_purchase_timestamp,
            '2017-12-30' order_approved_at,
            '2017-12-31' order_delivered_carrier_date))"""
    staging = (ROOT / 'sql/views/01_stg_orders.sql').read_text(encoding='utf-8')
    staging = staging.replace("read_csv_auto('data/olist_orders_dataset.csv', header=true)", raw)
    connection.execute(staging)
    actual = dict(connection.execute('SELECT order_id,is_late FROM stg_orders').fetchall())
    assert actual == {'same_day': False, 'next_day': True, 'missing': None,
                      'no_estimate': None, 'canceled': None}, actual
    connection.close()


def check(connection):
    for source in sorted((ROOT / 'sql' / 'views').glob('*.sql')):
        connection.execute(source.read_text(encoding='utf-8'))
    assert connection.execute('SELECT COUNT(*) FROM mart_order_delivery').fetchone()[0] == 96470
    assert connection.execute('SELECT COUNT(*) FROM mart_order_delivery WHERE is_late').fetchone()[0] == 6534
    assert connection.execute('SELECT COUNT(*) FROM mart_seller WHERE late_orders > delivered_orders').fetchone()[0] == 0
    correct = connection.execute("""
        WITH pairs AS (
            SELECT DISTINCT seller_id, order_id
            FROM read_csv_auto('data/olist_order_items_dataset.csv')
        )
        SELECT SUM(is_late::INTEGER) FROM pairs JOIN mart_order_delivery USING(order_id)
    """).fetchone()[0]
    assert connection.execute('SELECT SUM(late_orders) FROM mart_seller').fetchone()[0] == correct
    assert connection.execute('SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM mart_order_delivery').fetchone()[0] == 0
    assert connection.execute('SELECT ROUND(SUM(gmv),2) FROM mart_category').fetchone()[0] == 13591643.70
    assert connection.execute('SELECT ROUND(SUM(gmv),2) FROM mart_seller').fetchone()[0] == 13591643.70
    assert connection.execute('SELECT ROUND(SUM(gmv),2) FROM mart_order_delivery').fetchone()[0] == 13220248.93
    assert connection.execute('SELECT COUNT(*) FROM mart_seller WHERE late_rate < 0 OR late_rate > 1').fetchone()[0] == 0
    uncertainty_sql = (ROOT/'sql/analysis/06_delivery_uncertainty.sql').read_text(encoding='utf-8')
    uncertainty = connection.execute(connection.extract_statements(uncertainty_sql)[0]).fetchall()
    assert len(uncertainty) == 27
    assert sum(row[1] for row in uncertainty) == 96470
    for state, n, late, rate, lower, upper, flag in uncertainty:
        assert 0 <= lower <= rate <= upper <= 1, (state,rate,lower,upper)
        assert flag == ('meets_screening_minimum' if n >= 100 else 'small_sample_monitor_only')
    for source in sorted((ROOT / 'sql' / 'analysis').glob('*.sql')):
        for statement in connection.extract_statements(source.read_text(encoding='utf-8')):
            connection.execute(statement).fetchall()
    connection.close()
    print('PASS: SLA baseline, seller-order grain and all analysis queries')


def check_join_grains_and_calendar():
    connection = duckdb.connect()
    connection.execute("""
        CREATE TABLE fixture_orders AS
        SELECT * FROM (VALUES
          ('o1','c1','delivered','2018-01-01','2018-01-04','2018-01-03'),
          ('o2','c2','delivered','2018-03-01','2018-03-03','2018-03-04')
        ) t(order_id,customer_id,order_status,order_purchase_timestamp,
            order_delivered_customer_date,order_estimated_delivery_date)
        CROSS JOIN (SELECT '2018-01-01' order_approved_at,
                           '2018-01-02' order_delivered_carrier_date);
        CREATE TABLE fixture_customers AS
        SELECT * FROM (VALUES ('c1','u1','SP','city'),('c2','u2','RJ','city'))
        t(customer_id,customer_unique_id,customer_state,customer_city);
        CREATE TABLE fixture_items AS
        SELECT * FROM (VALUES
          ('o1','A','p1',10.0,1.0), ('o1','A','p2',20.0,2.0),
          ('o1','B','p3',30.0,3.0), ('o2','A','p4',40.0,4.0)
        ) t(order_id,seller_id,product_id,price,freight_value);
        CREATE TABLE fixture_reviews AS
        SELECT * FROM (VALUES ('o1',1),('o1',5),('o2',5)) t(order_id,review_score);
        CREATE TABLE fixture_sellers AS
        SELECT * FROM (VALUES ('A','SP','city','00100'),('B','RJ','city','00200'))
        t(seller_id,seller_state,seller_city,seller_zip_code_prefix);
    """)
    tables = {'orders': 'fixture_orders', 'customers': 'fixture_customers',
              'order_items': 'fixture_items', 'order_reviews': 'fixture_reviews',
              'sellers': 'fixture_sellers'}
    def use_fixtures(sql):
        for source, table in tables.items():
            sql = sql.replace(f"read_csv_auto('data/olist_{source}_dataset.csv', header=true)", table)
            sql = sql.replace(f"read_csv_auto('data/olist_{source}_dataset.csv')", table)
        return sql
    for name in ('01_stg_orders.sql','02_mart_order_delivery.sql','04_mart_seller.sql'):
        connection.execute(use_fixtures((ROOT/'sql/views'/name).read_text(encoding='utf-8')))
    rows = connection.execute('SELECT order_id,gmv,review_score,review_count FROM mart_order_delivery ORDER BY order_id').fetchall()
    assert rows == [('o1',60.0,3.0,2),('o2',40.0,5.0,1)], rows
    sellers = connection.execute('SELECT seller_id,delivered_orders,late_orders,late_rate,avg_review_score FROM mart_seller ORDER BY seller_id').fetchall()
    assert sellers == [('A',2,1,0.5,4.0),('B',1,1,1.0,3.0)], sellers
    sql = use_fixtures((ROOT/'sql/analysis/04_revenue_category.sql').read_text(encoding='utf-8'))
    months = connection.execute(connection.extract_statements(sql)[0]).fetchall()
    assert len(months) == 3 and months[1][1:3] == (0,0.0), months
    assert months[2][5] == 40.0 and months[2][6] is None, months
    connection.close()


if __name__ == '__main__':
    import os
    os.chdir(ROOT)
    check_sla_boundaries()
    check_join_grains_and_calendar()
    check(duckdb.connect())
