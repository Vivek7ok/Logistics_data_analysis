import os
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://postgres:Vivek%40123@localhost:5432/Logistics"
)

folder = r"d:\Data_Set\30_Logistics\Data"

files = [
    "carriers.csv",
    "customers.csv",
    "inventory.csv",
    "order_items.csv",
    "orders.csv",
    "products.csv",
    "shipments.csv",
    "warehouses.csv"
]

for file in files:
    path = os.path.join(folder, file)

    df = pd.read_csv(path)

    table_name = file.replace(".csv", "")

    df.to_sql(
        table_name,
        engine,
        if_exists="replace",
        index=False
    )

    print(f"{table_name} inserted successfully.")