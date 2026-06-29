---
version: 1.0.0
updated: 2026-04-21
breaking: false
---

# Security Patterns

## Role-based access

- Define permissions in DocType JSON — never hard-code `frappe.session.user` role checks as the sole gate.
- Use Frappe's permission system (Read/Write/Create/Delete/Submit/Cancel/Amend) — don't invent a parallel permission table.
- For row-level restrictions, use User Permissions (`frappe.core.doctype.user_permission`) rather than filtering in every query.

## Input sanitization

- Never render user-supplied content as raw HTML in Jinja templates — use `{{ value | e }}` (auto-escaped).
- Never pass user input directly into `frappe.db.sql()` string interpolation — use parameterized queries (see `api/conventions.md`).
- Strip HTML from free-text fields before storage if the field is not a rich-text field: `frappe.utils.strip_html(value)`.

## Secrets and credentials

- Never store API keys, passwords, or tokens in DocType fields that appear in list views or are exported via fixtures.
- Use Frappe's `Password` field type for any credential stored in the database — it encrypts at rest.
- For external service credentials, store in site `site_config.json` via `bench set-config`, not in app code or DocType records.
- Never commit `.env` files or `site_config.json` to version control.

## File uploads

- Validate file type and size server-side on every upload endpoint.
- Use `frappe.get_doc("File", ...)` to access uploaded files — do not construct file paths manually.
- Restrict uploads to Frappe's managed `public/files/` and `private/files/` — never write outside these.

## Whitelisted endpoint hygiene

- Every `@frappe.whitelist()` method must check permissions before acting.
- Methods that modify data must require POST — never perform writes inside GET-equivalent calls.
- Log security-sensitive actions (permission grants, record deletions, config changes) via `frappe.log_error()` or the Frappe Activity Log.
