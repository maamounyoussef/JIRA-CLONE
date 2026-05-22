# Apex Method Performance Report

Governor‑limit metrics captured from real test runs via the
`apex-method-monitor` skill. Each row is one measured execution.

| Date | Class.Method | N (input) | CPU (ms) | Heap (bytes) | SOQL | DML rows | DML stmts | Test method |
|------|--------------|----------:|---------:|-------------:|-----:|---------:|----------:|-------------|
| 2026-05-22 | ManageBacklogController.deleteTickets (before bulkification) | 24 | 272 | 1079 | 49 | 25 | 2 | measureDeleteTicketsGovernorUsage |
| 2026-05-22 | ManageBacklogController.deleteTickets (after bulkification) | 24 | 131 | 1015 | 26 | 25 | 2 | measureDeleteTicketsGovernorUsage |
| 2026-05-22 | TicketService.archiveSprintTickets (random test) | 50 | 18 | 742 | 12 | 50 | 1 | measureArchiveSprintGovernorUsage |
