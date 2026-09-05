
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
    # ── Step 1: Uncomment on first run to load base tables into SQL Server ──
    # 'users':       'data/processed/users_clean.csv',
    # 'orders':      'data/processed/orders_clean.csv',
    # 'order_items': 'data/processed/order_items_clean.csv',
    # 'products':    'data/processed/products_clean.csv',

    # ── Step 2: Run after 02_rfm_segmentation.ipynb ───────────
    'customer_segments': 'data/output/rfm_scored.csv'
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