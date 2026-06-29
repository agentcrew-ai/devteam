---
version: 1.0.0
updated: 2026-04-21
breaking: false
---

# Frappe Patterns

## hooks.py

Use `hooks.py` for all framework integration points. Never wire events in Python controller `__init__`.

### DocType events

```python
doc_events = {
    "Service Order": {
        "on_submit": "hsto_frappe.service.events.on_submit",
        "on_cancel": "hsto_frappe.service.events.on_cancel",
    }
}
```

- One handler function per event per DocType.
- Handler signature: `def on_submit(doc, method)` — always accept both args even if `method` is unused.

### Scheduled tasks

```python
scheduler_events = {
    "daily": ["hsto_frappe.tasks.daily.run"],
    "cron": {
        "0 6 * * 1": ["hsto_frappe.tasks.weekly_report.run"]
    }
}
```

- Put task logic in `<app>/tasks/`, one file per schedule bucket.
- Tasks must be idempotent — they may run more than once due to retries.

## patches.txt

For one-time data migrations run during `bench migrate`:

```
hsto_frappe.patches.v1_0.migrate_patient_status
```

Rules:
- One patch = one file in `patches/v<major>_<minor>/`.
- Never delete old patch entries from `patches.txt`.
- Patch function signature: `def execute():` with no arguments.

## Fixtures

Use fixtures to ship master data (roles, workflows, print formats):

```python
# hooks.py
fixtures = [
    "Role",
    {"dt": "Workflow", "filters": [["document_type", "in", ["Service Order"]]]},
]
```

Export with `bench export-fixtures`, commit JSON to `<app>/fixtures/`. Imported automatically on `bench migrate`.

## Controller conventions

- `validate()` — business rule checks; raise `frappe.ValidationError` on failure.
- `before_insert()` / `before_save()` — derived field population.
- `on_submit()` / `on_cancel()` — state transitions affecting other documents.
- Never use `__init__` for business logic.
- Keep controllers thin: extract complex logic into service modules at `<app>/<module>/service.py`.

## Client scripts

- Prefer server-side whitelisted methods over client scripts for any logic that touches data.
- Client scripts are for UI behavior only (field visibility, real-time filters).
- Store client scripts in the DocType JSON (`client_script` field) for version control.
