import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import warnings

# Hide unnecessary warnings for cleaner output
warnings.filterwarnings("ignore")

# --------------------------------------------------
# Plot settings: make charts cleaner and more readable
# --------------------------------------------------
sns.set_theme(style="whitegrid")
plt.rcParams.update({
    "figure.figsize": (12, 6),
    "axes.titlesize": 16,
    "axes.titleweight": "bold",
    "axes.labelsize": 12,
    "xtick.labelsize": 10,
    "ytick.labelsize": 10,
    "font.family": "DejaVu Sans"
})

# --------------------------------------------------
# Helper function to style each chart consistently
# --------------------------------------------------
def style_chart(ax, title, xlabel="", ylabel="", rotate_x=45):
    ax.set_title(title, fontsize=16, fontweight="bold", pad=15)
    ax.set_xlabel(xlabel, fontsize=12, labelpad=10)
    ax.set_ylabel(ylabel, fontsize=12, labelpad=10)
    ax.tick_params(axis="x", rotation=rotate_x)
    ax.grid(axis="y", linestyle="--", alpha=0.3)
    sns.despine(ax=ax)

# --------------------------------------------------
# Load CSV files
# --------------------------------------------------
df_carriers = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\carriers.csv")
df_customers = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\customers.csv")
df_inventory = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\inventory.csv")
df_order_items = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\order_items.csv")
df_orders = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\orders.csv")
df_products = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\products.csv")
df_shipments = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\shipments.csv")
df_warehouses = pd.read_csv(r"d:\Data_Set\30_Logistics\Data\warehouses.csv")

# --------------------------------------------------
# Merge all tables into one master dataframe
# --------------------------------------------------
df = (
    df_customers
    .merge(df_orders, on="customer_id", how="left")
    .merge(df_order_items, on="order_id", how="left")
    .merge(df_products, on="product_id", how="left")
    .merge(df_inventory, on=["product_id", "warehouse_id"], how="left")
    .merge(df_shipments, on="order_id", how="left")
    .merge(df_carriers, on="carrier_id", how="left")
    .merge(df_warehouses, on="warehouse_id", how="left")
)

# --------------------------------------------------
# Rename confusing duplicate columns for readability
# --------------------------------------------------
if "state_x" in df.columns:
    df = df.rename(columns={"state_x": "customer_state"})
if "state_y" in df.columns:
    df = df.rename(columns={"state_y": "warehouse_state"})
if "unit_price_x" in df.columns:
    df = df.rename(columns={"unit_price_x": "unit_price"})
if "unit_price_y" in df.columns and "unit_price" not in df.columns:
    df = df.rename(columns={"unit_price_y": "unit_price"})

# --------------------------------------------------
# Basic data inspection
# --------------------------------------------------
print("Dataset Shape:", df.shape)
print("\nColumn Names:\n", df.columns.tolist())
print("\nData Info:")
print(df.info())

print("\nMissing Values:\n", df.isnull().sum().sort_values(ascending=False))

print("\nDuplicate Rows:", df.duplicated().sum())

print("\nObject Column Summary:\n")
print(df.describe(include="object"))

# --------------------------------------------------
# Convert date columns safely
# --------------------------------------------------
date_columns = [
    "order_date",
    "shipment_date",
    "expected_delivery_date",
    "actual_delivery_date"
]

for col in date_columns:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors="coerce")

# --------------------------------------------------
# Feature engineering
# --------------------------------------------------
# Month column for monthly trend analysis
df["Month"] = df["order_date"].dt.to_period("M").dt.to_timestamp()

# Revenue calculation
# If your dataset uses a different price column name, rename it above first
df["Revenue"] = df["quantity"] * df["unit_price"]

# Processing time in days between order date and shipment date
df["processing_days"] = (df["shipment_date"] - df["order_date"]).dt.days

# --------------------------------------------------
# Correlation matrix for numeric columns
# --------------------------------------------------
numeric_df = df.select_dtypes(include="number")
corr = numeric_df.corr()

# --------------------------------------------------
# Key summary metrics
# --------------------------------------------------
total_customers = df_customers["customer_id"].nunique()
total_orders = df_orders["order_id"].nunique()
total_products = df_products["product_id"].nunique()
total_warehouses = df_warehouses["warehouse_id"].nunique()

print(
    f"\nTotal Customers: {total_customers}"
    f"\nTotal Orders: {total_orders}"
    f"\nTotal Products: {total_products}"
    f"\nTotal Warehouses: {total_warehouses}"
)

# State-wise summaries
print("\nTotal Warehouses in Each State:\n")
print(df_warehouses["state"].value_counts())

print("\nTotal Customers in Each State:\n")
print(df_customers["state"].value_counts())

# --------------------------------------------------
# 1) Transport mode count
# --------------------------------------------------
fig, ax = plt.subplots()
sns.countplot(data=df, x="transport_mode", ax=ax)
style_chart(ax, "Transport Mode Distribution", "Transport Mode", "Order Count", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 2) Average shipping cost, distance, and fuel cost by customer state
# --------------------------------------------------
fig, ax = plt.subplots()
state_costs = df.groupby("customer_state")[["shipping_cost", "distance_km", "fuel_cost"]].mean()
state_costs.plot(kind="line", marker="o", ax=ax)
style_chart(ax, "Average Shipping Metrics by Customer State", "Customer State", "Average Value", rotate_x=45)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 3) Average rating by transport mode
# --------------------------------------------------
fig, ax = plt.subplots()
transport_rating = df.groupby("transport_mode")["rating"].mean()
transport_rating.plot(kind="bar", ax=ax)
style_chart(ax, "Average Rating by Transport Mode", "Transport Mode", "Average Rating", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 4) Median discount by product category
# --------------------------------------------------
fig, ax = plt.subplots()
category_discount = df.groupby("category")["discount"].median().sort_values(ascending=False)
category_discount.plot(kind="bar", ax=ax)
style_chart(ax, "Median Discount by Category", "Category", "Median Discount", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 5) Top 5 most sold products by quantity
# --------------------------------------------------
fig, ax = plt.subplots()
top_products = (
    df.groupby("product_name")["quantity"]
    .sum()
    .sort_values(ascending=False)
    .head(5)
)
top_products.plot(kind="barh", ax=ax)
style_chart(ax, "Top 5 Best-Selling Products", "Total Quantity Sold", "Product Name", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 6) Median processing days by transport mode
# --------------------------------------------------
fig, ax = plt.subplots()
processing_by_mode = df.groupby("transport_mode")["processing_days"].median()
processing_by_mode.plot(kind="bar", ax=ax)
style_chart(ax, "Median Processing Days by Transport Mode", "Transport Mode", "Median Processing Days", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 7) Top 5 revenue-generating categories
# --------------------------------------------------
fig, ax = plt.subplots()
top_revenue_categories = (
    df.groupby("category")["Revenue"]
    .sum()
    .sort_values(ascending=False)
    .head(5)
)
top_revenue_categories.plot(kind="barh", ax=ax)
style_chart(ax, "Top 5 Revenue-Generating Categories", "Total Revenue", "Category", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 8) Monthly total orders trend
# --------------------------------------------------
fig, ax = plt.subplots()
monthly_orders = (
    df.groupby("Month")["order_id"]
    .nunique()
    .reset_index(name="Total Orders")
)
sns.lineplot(data=monthly_orders, x="Month", y="Total Orders", marker="o", ax=ax)
style_chart(ax, "Monthly Order Trend", "Month", "Total Orders", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 9) Monthly revenue trend
# --------------------------------------------------
fig, ax = plt.subplots()
monthly_revenue = (
    df.groupby("Month")["Revenue"]
    .sum()
    .reset_index(name="Total Revenue")
)
sns.lineplot(data=monthly_revenue, x="Month", y="Total Revenue", marker="o", ax=ax)
style_chart(ax, "Monthly Revenue Trend", "Month", "Total Revenue", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 10) Correlation heatmap for numeric fields
# --------------------------------------------------
fig, ax = plt.subplots(figsize=(14, 10))
sns.heatmap(corr, annot=True, fmt=".2f", cmap="coolwarm", ax=ax, linewidths=0.5)
style_chart(ax, "Correlation Heatmap", "", "", rotate_x=0)
ax.tick_params(axis='x', labelsize=6)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 11) Revenue by transport mode
# --------------------------------------------------
fig, ax = plt.subplots()
sns.barplot(data=df, x="transport_mode", y="Revenue", estimator=np.sum, errorbar=None, ax=ax)
style_chart(ax, "Revenue by Transport Mode", "Transport Mode", "Total Revenue", rotate_x=0)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 12) Revenue by category
# --------------------------------------------------
fig, ax = plt.subplots(figsize=(14, 6))
sns.barplot(data=df, x="category", y="Revenue", estimator=np.sum, errorbar=None, ax=ax)
style_chart(ax, "Revenue by Category", "Category", "Total Revenue", rotate_x=0)
ax.tick_params(axis='x', labelsize=6)
plt.tight_layout()
plt.show()

# --------------------------------------------------
# 13) Revenue by customer state
# --------------------------------------------------
fig, ax = plt.subplots(figsize=(14, 6))
sns.barplot(data=df, x="customer_state", y="Revenue", estimator=np.sum, errorbar=None, ax=ax)
style_chart(ax, "Revenue by Customer State", "Customer State", "Total Revenue", rotate_x=0)
ax.tick_params(axis='x', labelsize=6)
plt.tight_layout()
plt.show()