# Logistics & Supply Chain Dataset

Synthetic but business-realistic relational dataset for a logistics/supply-chain
analytics portfolio project. Total size ≈ 356 MB across 8 CSV files.

## Files

| File               | Rows       | Approx. Size | Description                              |
|--------------------|-----------:|-------------:|-------------------------------------------|
| customers.csv      | 50,000     | 3.3 MB       | Retail / Wholesale / Corporate customers  |
| products.csv       | 2,000      | 0.1 MB       | 10 categories, realistic price/weight     |
| warehouses.csv     | 25         | <0.1 MB      | Fulfillment centers in major Indian cities|
| carriers.csv       | 20         | <0.1 MB      | Real-style Indian/global carrier names    |
| orders.csv         | 1,800,000  | 119.7 MB     | Jan 2022 – Dec 2025                       |
| order_items.csv    | 3,962,138  | 134.7 MB     | 1–5 line items per order                  |
| shipments.csv      | 1,674,566  | 96.8 MB      | One per non-cancelled order               |
| inventory.csv      | 50,000     | 1.6 MB       | One row per warehouse × product           |
| **Total**          |            | **356.1 MB** |                                            |

`schema.sql` contains `CREATE TABLE` statements with all primary keys,
foreign keys, check constraints, and indexes.

## Relationships

```
customers (1)───< orders (M) >───(1) warehouses
                     │
                     ├───< order_items (M) >───(1) products
                     │
                     └───< shipments (0..1) >───(1) carriers

warehouses (1)───< inventory (M) >───(1) products
```

Cancelled orders intentionally have **no shipment row** (order never shipped).

## Business logic baked into the data

- **Seasonality**: order volume is weighted higher in Oct/Nov (Diwali season)
  and Dec (year-end/Christmas), lower in the April–June off-season, plus
  ~10-12% year-over-year growth from 2022 → 2025.
- **Order status mix**: ~85% Delivered, ~7% Cancelled, ~7% Returned, and a
  small "still open" tail (Processing / In Transit) concentrated in the last
  20 days of the data window (Dec 2025) — because those orders genuinely
  haven't resolved yet.
- **Missing values are logical, not random**: `actual_delivery_date` is NULL
  only for Cancelled, Processing, and In Transit orders — exactly the
  statuses where a real delivery date wouldn't exist yet.
- **Delays**: ~7.9% of resolved shipments are delayed by 1-10 days
  (within the requested 5-10% band); the rest arrive on time or early.
- **Geography-driven logistics**: distance_km is computed from real
  lat/long coordinates (haversine formula) between each customer's city and
  their assigned warehouse (70% nearest warehouse, 30% cross-region
  fulfillment, mirroring real 3PL network behavior). Transport mode
  (Road/Rail/Air/Sea) and shipping/fuel cost scale with that distance.
- **Customer-type-driven order economics**: Retail customers buy 1-3 units
  with small/no discounts; Wholesale buys 5-20 units at 5-15% discount;
  Corporate buys 10-50 units at 10-20% discount — driving realistic
  total_amount and inventory demand patterns.
- **Category popularity**: Groceries and Apparel are the highest-frequency
  categories; Electronics and Furniture are lower-frequency but higher
  average order value.

## Regenerating / adjusting the dataset

The generator lives in `/home/claude/gen/` (`common.py`, `dims.py`,
`facts.py`, `build.py`). Row counts are controlled by `N_CUSTOMERS`,
`N_PRODUCTS`, and `N_ORDERS` at the top of `build.py` — everything else
(order_items, shipments, inventory) scales automatically from those.
