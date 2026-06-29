---
version: 1.0.0
updated: 2026-04-21
breaking: false
---

# API Conventions

## Whitelisting

All server-side methods callable from client must use the `@frappe.whitelist()` decorator:

```python
@frappe.whitelist()
def get_patient_summary(patient_id):
    ...
```

- Use `@frappe.whitelist(allow_guest=True)` only for truly public endpoints (login page, public forms).
- Never bypass permission checks inside a whitelisted method by assuming the caller is trusted.

## Permission enforcement

Check permissions before any data access:

```python
frappe.has_permission("Patient Record", "read", throw=True)
```

For document-level checks use `frappe.get_doc()` followed by `doc.check_permission()`. Never roll your own permission logic.

## Error responses

Always raise errors via `frappe.throw()` — never return error dicts manually:

```python
frappe.throw(_("Patient {0} not found").format(patient_id), frappe.DoesNotExistError)
```

Standard exception types:

| Situation | Exception |
|---|---|
| Record not found | `frappe.DoesNotExistError` |
| Permission denied | `frappe.PermissionError` |
| Invalid input | `frappe.ValidationError` |
| Duplicate entry | `frappe.DuplicateEntryError` |

## Response format

For whitelisted methods returning structured data, return a plain dict or list — Frappe serializes it automatically:

```python
return {"status": "ok", "data": {...}}
```

For paginated list endpoints always return:

```python
{"data": [...], "total": int, "page": int, "page_length": int}
```

## Input validation

- Validate all user-supplied input at the method boundary before any DB call.
- Use `frappe.utils.cstr()`, `cint()`, `flt()` to coerce types safely.
- Never concatenate user input into `frappe.db.sql()` strings. Use parameterized queries:

```python
frappe.db.sql("SELECT name FROM `tabPatient` WHERE status = %s", (status,))
```

## Translations

Wrap all user-visible strings in `_()`:

```python
frappe.throw(_("Record is locked and cannot be edited."))
```
