# retry-safety changelog

## 0.3.0 - 2026-10-20

- Added the stale-leftover test (can the next run tell a crashed run's lock, temp file, or claimed job from a live one, by evidence that holds at any stop point) and the write-temp-then-rename shape. Adapted from pstack by Lauren Tan (MIT).

## 0.2.0 - 2026-08-08

- Report contract now follows the shared audit report format: every finding carries severity and effort, findings group by severity, and the report ends with a leverage-sorted backlog, so reports compose with the rest of the audit roster and feed expedite.

## 0.1.0 - 2026-07-12

- Initial release: adapted from alp-river's correctness reviewer (MIT, Alper Ortac).
