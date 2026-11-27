"""Derive independent CSV/SQL expectations and a Desktop DAX acceptance query."""
from pathlib import Path
import json
import duckdb
ROOT = Path(__file__).resolve().parents[1]
db = duckdb.connect()
for path in sorted((ROOT/'sql/views').glob('*.sql')):
    db.execute(path.read_text(encoding='utf-8'))
db.execute("CREATE VIEW raw_items AS SELECT * FROM read_csv_auto('data/olist_order_items_dataset.csv')")
cases = []
def case(name, sql, dax, blank=False):
    value = db.execute(sql).fetchone()[0]
    cases.append({'case':name,'sql':sql,'expected':float(value) if value is not None else None,'dax':dax,'blank':blank})

for n in (29,30):
    seller = db.execute(f"SELECT i.seller_id FROM raw_items i JOIN mart_order_delivery d USING(order_id) GROUP BY i.seller_id HAVING count(distinct i.order_id)={n} ORDER BY i.seller_id LIMIT 1").fetchone()[0]
    filt = f'Sellers[seller_id] = "{seller}"'
    sql = f"SELECT count(distinct d.order_id) FROM mart_order_delivery d JOIN raw_items i USING(order_id) WHERE i.seller_id='{seller}'"
    case(f'seller_{n}_eligible',sql,f'CALCULATE([Seller Eligible Orders], {filt})')
    case(f'seller_{n}_rate',f"SELECT {'NULL' if n<30 else 'count(distinct CASE WHEN d.is_late THEN d.order_id END)::DOUBLE/count(distinct d.order_id)'} FROM mart_order_delivery d JOIN raw_items i USING(order_id) WHERE i.seller_id='{seller}'",f'CALCULATE([Seller Late Rate], {filt})',n<30)

seller=db.execute("SELECT seller_id FROM raw_items GROUP BY seller_id HAVING count(*)>count(distinct order_id) ORDER BY count(*) DESC LIMIT 1").fetchone()[0]
case('multi_item_seller',f"SELECT count(distinct d.order_id) FROM mart_order_delivery d JOIN raw_items i USING(order_id) WHERE i.seller_id='{seller}'",f'CALCULATE([Seller Eligible Orders], Sellers[seller_id] = "{seller}")')
order=db.execute('SELECT order_id FROM raw_items GROUP BY order_id HAVING count(distinct seller_id)>1 ORDER BY count(*) DESC, order_id LIMIT 1').fetchone()[0]
case('multi_seller_order',f"SELECT count(distinct order_id) FROM mart_order_delivery WHERE order_id='{order}'",f'CALCULATE([Delivered Orders], Orders[order_id] = "{order}")')
participants=db.execute(f"SELECT DISTINCT seller_id FROM raw_items WHERE order_id='{order}' ORDER BY seller_id").fetchall()
for idx,(participant,) in enumerate(participants):
    case(f'multi_seller_pair_{idx+1}',f"SELECT count(distinct d.order_id) FROM mart_order_delivery d JOIN raw_items i USING(order_id) WHERE d.order_id='{order}' AND i.seller_id='{participant}'",f'CALCULATE([Seller Eligible Orders], Orders[order_id] = "{order}", Sellers[seller_id] = "{participant}")')
case('multi_seller_pair_total',f"SELECT count(distinct i.seller_id) FROM mart_order_delivery d JOIN raw_items i USING(order_id) WHERE d.order_id='{order}'",f'CALCULATE(SUMX(VALUES(Sellers[seller_id]), [Seller Eligible Orders]), Orders[order_id] = "{order}")')
cats="'health_beauty','watches_gifts'"
categoryfrom="raw_items i JOIN read_csv_auto('data/olist_products_dataset.csv') p USING(product_id) LEFT JOIN read_csv_auto('data/product_category_name_translation.csv') t USING(product_category_name)"
catwhere=f"t.product_category_name_english IN ({cats})"
catfilter='TREATAS({"health_beauty", "watches_gifts"}, CategoryMart[category])'
case('multi_category_gmv',f'SELECT sum(price) FROM {categoryfrom} WHERE {catwhere}',f'CALCULATE([GMV], {catfilter})')
case('multi_category_freight',f'SELECT sum(freight_value)/(sum(price)+sum(freight_value)) FROM {categoryfrom} WHERE {catwhere}',f'CALCULATE([Freight Share], {catfilter})')
case('multi_category_aov',f'SELECT sum(price)/count(distinct order_id) FROM {categoryfrom} WHERE {catwhere}',f'CALCULATE([AOV], {catfilter})')
identity=db.execute("SELECT customer_unique_id FROM read_csv_auto('data/olist_customers_dataset.csv') GROUP BY 1 HAVING count(*)>1 ORDER BY count(*) DESC LIMIT 1").fetchone()[0]
case('identity_one_person',f"SELECT count(distinct customer_unique_id) FROM read_csv_auto('data/olist_customers_dataset.csv') WHERE customer_unique_id='{identity}'",f'CALCULATE([Unique Customers], Customers[customer_unique_id] = "{identity}")')
case('identity_repeat_person','SELECT 1',f'CALCULATE([Repeat Buyers], Customers[customer_unique_id] = "{identity}")')
for label,metric in [('review','avg(review_score)'),('reviewed','count(review_score)')]:
    measure='Average Review' if label=='review' else 'Reviewed Orders'
    case('jan2018_'+label,f"SELECT {metric} FROM mart_order_delivery WHERE order_month=DATE '2018-01-01'",f'CALCULATE([{measure}], Orders[Order Month] = "2018-01")')
case('empty_population','SELECT NULL','CALCULATE([Delivered Orders], Orders[order_id] = "NO_SUCH_ORDER")',True)
case('empty_rate','SELECT NULL','CALCULATE([Late Delivery Rate], Orders[order_id] = "NO_SUCH_ORDER")',True)
mom="WITH m AS (SELECT order_month, avg(is_late::INT)*100 rate FROM mart_order_delivery GROUP BY 1) SELECT a.rate-b.rate FROM m a JOIN m b ON b.order_month=a.order_month-INTERVAL '1 month' WHERE a.order_month=DATE '2018-01-01'"
case('mom_jan2018',mom,'CALCULATE([Late Rate MoM pp], Orders[Order Month] = "2018-01")')
case('mom_low_volume_comparator','SELECT NULL','CALCULATE([Late Rate MoM pp], Orders[Order Month] = "2016-10")',True)
case('mom_missing_comparator','SELECT NULL','CALCULATE([Late Rate MoM pp], Orders[Order Month] = "2017-01", Customers[customer_state] = "SP")',True)
case('mom_multiple_months','SELECT NULL','[Late Rate MoM pp]',True)
case('mom_partial_month','SELECT NULL','CALCULATE([Late Rate MoM pp], Orders[order_purchase_timestamp] >= DATE(2018,1,10), Orders[order_purchase_timestamp] < DATE(2018,2,1))',True)
case('mom_status_multi','SELECT 1','IF([Delivery MoM] = "Select one month",1,0)')
case('mom_status_missing','SELECT 1','IF(CALCULATE([Delivery MoM], Orders[Order Month] = "2016-10") = "Insufficient data",1,0)')
case('mom_status_partial','SELECT 1','IF(CALCULATE([Delivery MoM], Orders[order_purchase_timestamp] >= DATE(2018,1,10), Orders[order_purchase_timestamp] < DATE(2018,2,1)) = "Full month needed",1,0)')
rows=[]
for c in cases:
    expected='BLANK()' if c['blank'] else repr(c['expected'])
    rows.append(f'ROW("Case", "{c["case"]}", "Actual", {c["dax"]}, "Expected", {expected}, "BlankExpected", {str(c["blank"]).upper()}())')
query='EVALUATE\nVAR TestRows = UNION(\n'+',\n'.join(rows)+'\n)\nVAR Checked = ADDCOLUMNS(TestRows, "Pass", IF([BlankExpected], IF(ISBLANK([Actual]),1,0), IF(NOT ISBLANK([Actual]) && ABS([Actual]-[Expected]) < 0.00001,1,0)))\nRETURN ROW("Passed", SUMX(Checked,[Pass]), "Total", COUNTROWS(Checked), "Failures", CONCATENATEX(FILTER(Checked,[Pass]=0),[Case], ", "))\n'
dest=ROOT/'evidence/acceptance';dest.mkdir(parents=True,exist_ok=True)
(dest/'native_cases.json').write_text(json.dumps(cases,indent=2),encoding='utf-8')
(dest/'native_acceptance.dax').write_text(query,encoding='utf-8')
print(f'Prepared {len(cases)} independent SQL cases; multi-item seller {seller}; multi-seller order {order}; identity {identity}')
db.close()

