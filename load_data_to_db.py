
import pandas as pd
import urllib
from sqlalchemy import create_engine

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=thelook;"
    "Trusted_Connection=yes;"
)

engine = create_engine(
    f"mssql+pyodbc:///?odbc_connect={params}",
    fast_executemany=True
)

tables = {
    # 'distribution_centers': 'data/distribution_centers.csv',
    # 'inventory_events': 'data/inventory_events.csv',
    # 'events': 'data/events_clean.csv'
    # 'users': 'data/users_clean.csv',
    # 'orders': 'data/orders_clean.csv',
    # 'order_items': 'data/order_items_clean.csv',
    # 'products': 'data/products_clean.csv'
    'customer_segments': 'data/output_query/rfm_scored.csv'
}

for table_name, file_path in tables.items():
    print(f'Importing {table_name}...')
    
    first = True
    for chunk in pd.read_csv(file_path, chunksize=50000):
        chunk.to_sql(
            table_name,
            engine,
            if_exists='replace' if first else 'append',
            index=False,
            chunksize=10000
        )
        first = False
    
    print(f'Done: {table_name}')