---
version: 1.0.0
updated: 2026-04-21
breaking: false
---

# Data Schema Conventions

## DocType naming

- DocType names: `PascalCase`, singular noun (e.g., `Patient Record`, `Service Order`)
- Field names: `snake_case` (e.g., `patient_name`, `service_date`)
- Child table DocType names: suffix with `Item` or `Detail` (e.g., `Service Order Item`)
- Module names: `snake_case`, match the app module directory

## Required audit fields

Every custom DocType must rely on Frappe's built-in audit fields — do not redefine them:

| Field | Type | Notes |
|---|---|---|
| `owner` | Data | Auto-set by Frappe on insert |
| `modified_by` | Data | Auto-set by Frappe on save |
| `creation` | Datetime | Auto-set by Frappe on insert |
| `modified` | Datetime | Auto-set by Frappe on save |

If a business audit trail is needed beyond these, add `amended_from` (Link to same DocType) and enable "Is Submittable".

## Soft delete

- Use `docstatus` for submittable documents: `0` = Draft, `1` = Submitted, `2` = Cancelled.
- For non-submittable documents that need disabling: add an `is_active` Check field (default 1). Never hard-delete in application logic.

## Link fields

- Always set `options` to the target DocType name.
- Always add a corresponding `fetch_from` for the human-readable label if displaying in a list view.
- Never store denormalized data manually — use `fetch_from` so Frappe keeps it in sync.

## Select / Enum fields

- Use `Select` field type with newline-separated options in the `options` property.
- First option is the default; keep it meaningful (not blank) unless "not yet set" is a valid business state.
- Do not use magic numbers — always named options.

## Child tables

- Child DocType must have `istable = 1`.
- Parent link field name must be `parent` (Frappe convention — do not rename).
- Always define `parenttype` and `parentfield` in the child DocType JSON.
- Row ordering via `idx` field is automatic — do not manage it manually.

## Naming series

- Define naming series in `autoname` property: e.g., `SRV-.YYYY.-.#####`.
- If human-assigned names are needed, set `autoname = prompt` and validate uniqueness in the controller.

## Schema change process

1. Update the DocType JSON in `doctype/<name>/<name>.json`.
2. Run `bench migrate` — never write raw `ALTER TABLE` SQL.
3. If a data backfill is needed, add a patch in `patches.txt` and a corresponding patch file.
4. Update this file's `version` and add a `CHANGELOG.md` entry if the convention itself changed.
