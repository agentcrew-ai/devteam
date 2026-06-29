---
version: 1.0.0
updated: 2026-04-29
breaking: false
---

# Saleor Integration

How the `hsto_frappe` Frappe app connects to a Saleor storefront via GraphQL.

---

## File structure

```
hsto_frappe/
├── saleor/                                         ← service layer
│   ├── client.py                                   ← GraphQL HTTP client
│   └── api.py                                      ← @frappe.whitelist() methods
└── hsto_frappe/                                    ← Frappe module
    ├── saleor_settings/
    │   ├── saleor_settings.json                    ← Single DocType (credentials)
    │   └── saleor_settings.py
    └── saleor_order/
        ├── saleor_order.json                       ← DocType (order records)
        ├── saleor_order.py
        └── queries/
            └── fetch_orders.graphql                ← reusable GraphQL query
```

---

## 1. First-time setup

### Step 1 — migrate the database

Start the bench services, then run:

```bash
bench start                          # Terminal 1 — keep running
bench --site site.local migrate      # Terminal 2
```

This creates the `Saleor Settings` and `Saleor Order` tables.

> **Troubleshooting:** if `bench --site` says "No such option", the `config/pids/` directory is missing.
> Fix with `mkdir -p config/pids` from the bench root, then retry.

### Step 2 — enter credentials

1. Open the Frappe desk at `http://site.local:8000`.
2. Search for **Saleor Settings** in the search bar.
3. Fill in:
   - **Saleor GraphQL URL** — e.g. `https://yourstore.saleor.cloud/graphql/`
   - **Auth Token** — a Saleor service account token (Dashboard → Settings → API keys)
4. Save.

---

## 2. Fetching orders

### From Python (server-side)

```python
from hsto_frappe.saleor.api import fetch_orders

# All unfulfilled orders
orders = fetch_orders(filter={"status": "UNFULFILLED"})

# With sort
orders = fetch_orders(
    filter={"status": "UNFULFILLED"},
    sort_by={"field": "NUMBER", "direction": "DESC"},
)
```

### From JavaScript (client-side)

```js
frappe.call({
    method: "hsto_frappe.saleor.api.fetch_orders",
    args: {
        filter: JSON.stringify({ status: "UNFULFILLED" }),
        sort_by: JSON.stringify({ field: "NUMBER", direction: "DESC" }),
    },
    callback: r => console.log(r.message),
});
```

Each item in the returned list matches the fields in the stored query:

| Key | Type | Description |
|---|---|---|
| `id` | string | Saleor node ID |
| `number` | int | Human-readable order number |
| `status` | string | e.g. `UNFULFILLED`, `FULFILLED` |
| `paymentStatus` | string | e.g. `FULLY_CHARGED` |
| `isShippingRequired` | bool | |
| `canFinalize` | bool | |
| `isPaid` | bool | |
| `userEmail` | string | Customer email |
| `customerNote` | string | |
| `created` | datetime | ISO 8601 string from Saleor |

---

## 3. Stored GraphQL query

The query is version-controlled at:

```
hsto_frappe/hsto_frappe/saleor_order/queries/fetch_orders.graphql
```

```graphql
query DevModeRun($filter: OrderFilterInput, $sortBy: OrderSortingInput) {
  orders(first: 10, filter: $filter, sortBy: $sortBy) {
    edges {
      node {
        id
        number
        status
        isShippingRequired
        canFinalize
        created
        customerNote
        paymentStatus
        userEmail
        isPaid
      }
    }
  }
}
```

To add a new query (e.g. for products), drop a `.graphql` file in the same `queries/` directory and load it with:

```python
from hsto_frappe.saleor.client import load_query, run_query

gql = load_query("hsto_frappe/saleor_order/queries/your_query.graphql")
data = run_query(gql, variables={...})
```

---

## 4. Creating a Saleor Order record

Each Saleor Order document maps one-to-one with an order fetched from Saleor.

- `autoname = prompt` — you supply the document name when creating (e.g. the Saleor order number).
- The field schema is fixed; only the name changes per record.

To create one programmatically:

```python
import frappe

order_data = orders[0]   # from fetch_orders()

doc = frappe.get_doc({
    "doctype": "Saleor Order",
    "name": str(order_data["number"]),
    "saleor_id": order_data["id"],
    "order_number": order_data["number"],
    "status": order_data["status"],
    "payment_status": order_data["paymentStatus"],
    "is_shipping_required": order_data["isShippingRequired"],
    "can_finalize": order_data["canFinalize"],
    "is_paid": order_data["isPaid"],
    "user_email": order_data["userEmail"],
    "customer_note": order_data.get("customerNote", ""),
    "saleor_created": order_data["created"],
})
doc.insert(ignore_permissions=True)
```

---

## 5. How the client module works

`hsto_frappe/saleor/client.py` exposes two functions:

| Function | Purpose |
|---|---|
| `run_query(gql, variables)` | POST to Saleor GraphQL, return `data` dict. Raises `frappe.throw` on HTTP errors or GraphQL errors. |
| `load_query(relative_path)` | Read a `.graphql` file relative to the `hsto_frappe` app root. |

Credentials are read from **Saleor Settings** on every call — no restart needed after updating them.
