---
version: 1.0.0
updated: 2026-08-25
breaking: false
---

# MCP Server Adoption

How a team adds a Model Context Protocol server to its agent toolchain: which identity the agent acts as, where configuration lives, how credentials are supplied, and how access is verified and revoked. This is the generic pattern. Server names, URLs, workspace identifiers, and item names belong in the consuming environment's overlay — **never** in this library.

Secrets handling here defers to the agent secrets standard; this document covers only what is specific to MCP.

## Principle

An MCP server extends what an agent can do, and usually what it can *change*. Adoption is therefore an access-control decision before it is a configuration task. Decide the identity model first, then wire it.

## Identity model

Pick one per server, deliberately:

**Per-person identity (default for attributed tools).** Each team member authenticates as themselves. Use this whenever the upstream system records who did what — issue trackers, ticketing, source control, chat. The upstream permission model does the access control for free, actions are correctly attributed, and offboarding is deactivating one seat.

**Scoped service account (default for unattended automation).** One narrow identity for pipelines, cron jobs, and headless runs where no human is present to authenticate. Scope it to exactly the resources the job needs. Follow the agent secrets standard for how the credential reaches the process.

**Do not use a shared human account.** It defeats attribution, and revoking one person's access forces a rotation for everybody.

## Configuration placement

**User-global** configuration covers servers a person uses across every project. It is per-machine and never committed.

**Project-scoped** configuration (a checked-in MCP config file at the repo root) covers servers the project itself requires, so a new clone gets the same toolchain. Commit the server definition. Never commit a credential.

When both define the same server, the project-scoped definition is the one the team shares and the one that should be authoritative for project work.

## Credentials

Two authentication shapes, and they have different onboarding costs:

**Interactive OAuth.** The config holds a URL and no secret. Each person authorizes in a browser on first use. Nothing sensitive is stored in the config file, which makes it safe to commit, but it cannot work in a headless or scheduled context.

**Bearer token.** The config references an environment variable rather than embedding the value. The variable is populated at launch from the password manager per the agent secrets standard. This works unattended.

A configuration file must never contain a literal credential, in either shape.

## Verification

**Confirm a process exists.** A server listed in configuration is not evidence that it is running. Startup handshakes time out silently, dependencies fail to resolve, and the agent then behaves as though the tool simply has nothing to say. Check for the running process, or make one trivial call and confirm a real response, before declaring a server adopted.

Verify at the identity level too: the first call should confirm *which* account the agent is acting as, not just that a call succeeded.

## Offboarding

Revocation happens upstream, not in configuration. Deactivate the person's account or rotate the service credential. Removing a line from a config file on one machine is not revocation.

## Overlay responsibilities

The consuming environment's overlay carries, for each adopted server: the server name and endpoint, the chosen identity model and why, which workspaces or resources are in scope, any cross-referencing conventions the team applies when writing into that system, and the provisioning and offboarding runbook.
