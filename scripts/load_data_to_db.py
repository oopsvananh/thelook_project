"""
Loads cleaned CSV files into the SQL Server `thelook` database.

Usage
-----
1. Run notebooks/01_data_cleaning.ipynb first (outputs -> data/processed/)
2. Uncomment the 4 base-table rows below and run this script once to
   load users/orders/order_items/products before running the SQL files.
3. After running sql/customer_analysis.sql (RFM prep section) and
   notebooks/02_rfm_segmentation.ipynb, run this script again with only
   `customer_segments` uncommented to load the scored RFM output.
"""

import urllib.parse

import pandas as pd
from sqlalchemy import create_engine

SERVER = r"localhost\SQLEXPRESS"
DATABASE = "thelook"
CHUNK_SIZE = 50_000

TABLES = {
    # --- Step 1: base tables (uncomment, run once after data cleaning) ---
    # "users":       "data/processed/users_clean.csv",
    # "orders":      "data/processed/orders_clean.csv",
    # "order_items": "data/processed/order_items_clean.csv",
    # "products":    "data/processed/products_clean.csv",

    # --- Step 2: RFM output (uncomment after running 02_rfm_segmentation.ipynb) ---
    "customer_segments": "data/output/rfm_scored.csv",
}


def build_engine(server: str, database: str):
    params = urllib.parse.quote_plus(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
    )
    return create_engine(f"mssql+pyodbc:///?odbc_connect={params}", fast_executemany=True)


def load_csv_to_table(engine, table_name: str, file_path: str, chunksize: int = CHUNK_SIZE):
    print(f"Importing {table_name} from {file_path} ...")
    first_chunk = True
    for chunk in pd.read_csv(file_path, chunksize=chunksize):
        chunk.to_sql(
            table_name,
            engine,
            if_exists="replace" if first_chunk else "append",
            index=False,
            chunksize=10_000,
        )
        first_chunk = False
    print(f"Done: {table_name}")


def main():
    engine = build_engine(SERVER, DATABASE)
    for table_name, file_path in TABLES.items():
        load_csv_to_table(engine, table_name, file_path)


if __name__ == "__main__":
    main()