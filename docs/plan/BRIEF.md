# Planner brief: Cashew x Firefly III

Repo: this folder (fork of jameskokoska/Cashew, Flutter, app in `budget/`). Branch `firefly-sync`. Remote origin = github madratzz/app-cashew-x-firefly (public, GPL-3.0 — keep it).

Goal: Cashew app with FULL Firefly III feature support, Firefly server as source of truth (v6.6.2, API v1, HTTPS, Personal Access Token auth). Local Drift DB stays as offline cache; two-way sync. Google Drive sync disabled when Firefly mode is on.

Known facts: Drift tables in `budget/lib/database/tables.dart` (schemaVersion 46): Wallets, Transactions (pairedTransactionFk for transfers), Categories (with subcategories), CategoryBudgetLimits, Budgets, Objectives, AssociatedTitles, DeleteLogs (deletion tracking), dateTimeModified on every row. Existing Drive sync: `budget/lib/struct/syncClient.dart`. Missing in Cashew: expense/revenue accounts (payees), tags (Labels commented out), split transactions, liabilities, rules, multi-currency foreign amounts.

Phases: 1 core sync (settings URL+token, accounts/categories/transactions/transfers), 2 budgets+limits, piggy banks<->Objectives, bills/recurrences, 3 payees, tags, splits, liabilities, currencies, attachments, 4 rules UI (trigger server rules).

Your job: write `docs/plan/PLAN.md` — an executable plan split into independent work packages that can run IN PARALLEL in separate git worktrees with minimal file overlap. For each package: id, title, branch name `feature-<x>`, files owned, dependencies, acceptance criteria (incl. `flutter analyze` / tests), and suggested worker (Codex for heavy implementation, Claude for UI/integration). Include an entity-mapping table, sync algorithm (id mapping table, conflict rule, pagination, deletes), and secret handling (token in flutter_secure_storage, never committed). Verify API shapes against the Firefly API docs (https://api-docs.firefly-iii.org) where useful. Do NOT write app code. Do NOT start agents. No secrets in files.
When done: `hc send t28x "PLAN READY docs/plan/PLAN.md"`; if stuck, `hc send t28x "STUCK: ..."`.

## Platforms (added by user)
Ship native apps for iOS, Android, macOS, Linux and Windows (Flutter desktop targets). Add a work package that enables/creates missing desktop platform folders, fixes plugins without desktop support (Google sign-in, notifications, biometrics, secure storage, file pickers, home widgets) with platform guards, and sets up GitHub Actions CI building all 5 targets (artifacts per release tag). Firefly sync must work identically on every platform.
