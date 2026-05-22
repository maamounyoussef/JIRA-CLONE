# Name: apex-method-monitor

# Description:

	After creating or editing ANY Apex controller method that runs SOQL or SOSL,
	offer to profile it: generate a governor‑limit test method, RUN it, read the real
	numbers back from the debug log, and append them to a persistent report file
	(`docs/apex-method-report.md`). The report tracks, per method:
	CPU time (ms), Heap (bytes), SOQL queries, DML rows processed, DML statements.

	TRIGGER (offer this, do not run silently) when you have just written or modified
	an `@AuraEnabled` method in `classes/controller/**` whose body contains a SOQL
	`[SELECT ...]`, a SOSL `[FIND ...]`, or a query/DML helper call. After the method
	is in place, ASK the user whether to create a monitoring report for it.

	SKIP when the method does no SOQL/SOSL/DML (pure computation), or the user has
	already declined for this method in the current session.

	GOAL: every data‑touching controller method gets a reproducible, measured
	performance record — generated from an actual test run, never estimated.

---

## ROLE

	You are a performance‑measurement assistant for the Apex controller layer. You do
	not guess numbers. When a controller SOQL/SOSL method is finished you ask once
	whether to monitor it; if yes, you (1) generate a governor test method, (2) run
	it, (3) parse the real metrics from the log, and (4) record them in the report
	file. The numbers in the report ALWAYS come from a real execution.

---

## EXECUTION CONTRACT (run in order)

	### Step 1 — ASK (one question, after the method exists)

	Once the controller method is written/edited, ask the user with the interactive
	**`AskUserQuestion`** tool (the MCP "ask user" question UI) — NOT a plain‑text
	question in your reply. This presents selectable options and records the answer.

	- `header`: "Monitor method" (≤ 12 chars target; keep it short)
	- `question`: "Create a monitoring report for `<Class>.<method>`? I'll generate a
	  governor‑limit test, run it, and record CPU / Heap / SOQL / DML‑rows /
	  DML‑statements in `docs/apex-method-report.md`."
	- `multiSelect`: false
	- `options`:
	  1. **Yes, generate & run** (Recommended) — "Generate the governor test, run it,
	     and append the real metrics to the report."
	  2. **No, skip** — "Don't profile this method."

	Read the selected option from the tool result. If **No, skip** → stop, do nothing
	else. If **Yes** → continue to Step 2. (The user may also type a custom "Other"
	answer — honor it.)

	### Step 2 — GENERATE the test method

	Add a test method to the feature's governor test class
	(`classes/controller/<feature>/<Class>GovernorTest.cls`; create it if missing,
	following `ManageBacklogControllerGovernorTest.cls`). The method MUST:

	- Build all prerequisite data with **every required field set per
	  `OBJECT_VALIDATION_LWC_APEX.md`** (use the "for apex and store" column).
	- Size the input to the method's realistic bulk case (e.g. the validator cap, or a
	  representative N). State N in the report.
	- Measure ONLY the call, isolated from setup:

	```apex
	Test.startTest();                       // fresh governor context — excludes setup
	Integer soqlBefore    = Limits.getQueries();
	Integer dmlRowBefore  = Limits.getDmlRows();
	Integer dmlStmtBefore = Limits.getDmlStatements();
	Integer heapBefore    = Limits.getHeapSize();   // capture CPU/heap last (closest to call)
	Integer cpuBefore     = Limits.getCpuTime();

	APIResponse res = <Class>.<method>(/* args */);

	Integer cpuUsed     = Limits.getCpuTime()       - cpuBefore;   // CPU/heap first after call
	Integer heapUsed    = Limits.getHeapSize()      - heapBefore;
	Integer soqlUsed    = Limits.getQueries()       - soqlBefore;
	Integer dmlRowUsed  = Limits.getDmlRows()       - dmlRowBefore;
	Integer dmlStmtUsed = Limits.getDmlStatements() - dmlStmtBefore;
	Test.stopTest();

	System.debug('APEX_METRIC|<Class>.<method>|N=<n>|CPU=' + cpuUsed
	    + '|HEAP=' + heapUsed + '|SOQL=' + soqlUsed
	    + '|DMLROWS=' + dmlRowUsed + '|DMLSTMT=' + dmlStmtUsed);

	Assert.isTrue(res.success, 'Method should succeed; got: ' + res.message);
	```

	The single `APEX_METRIC|...` debug line is the machine‑readable payload you parse
	in Step 4 — keep that exact pipe‑delimited format.

	### Step 3 — RUN the test and read the real result

	Deploy and run only this test, capturing the debug log:

	```
	sf project deploy start -d force-app/main/default/classes
	sf apex run test --tests <Class>GovernorTest.<testMethod> \
	    --result-format human --code-coverage --wait 10
	```

	Then read the `APEX_METRIC|...` line from the test's debug log (e.g. via
	`sf apex get log` or the run output). If the test fails, fix the cause (often a
	missing required field or an uninitialized rollup) and re‑run — do not record
	numbers from a failed run.

	### Step 4 — WRITE / APPEND the report

	Target file: `docs/apex-method-report.md`.

	- If it does NOT exist, create it with the header block below.
	- If it exists, APPEND one new row (never rewrite prior rows — the file is a
	  running history).

	Header (only when creating the file):

	```markdown
	# Apex Method Performance Report

	Governor‑limit metrics captured from real test runs via the
	`apex-method-monitor` skill. Each row is one measured execution.

	| Date | Class.Method | N (input) | CPU (ms) | Heap (bytes) | SOQL | DML rows | DML stmts | Test method |
	|------|--------------|----------:|---------:|-------------:|-----:|---------:|----------:|-------------|
	```

	Row to append (values pulled from the `APEX_METRIC` line):

	```markdown
	| 2026-05-22 | ManageBacklogController.deleteTickets | 24 | 131 | 1015 | 26 | 25 | 2 | measureDeleteTicketsGovernorUsage |
	```

	Use today's date, the real parsed values, and the test method name. After writing,
	tell the user the row added and flag anything near a limit (SOQL > 80, CPU > 8000,
	DML rows > 8000, DML stmts > 120).

---

## NOTES

	- Numbers are never estimated or copied between methods — always from a fresh run.
	- Re‑profiling after an optimization adds a NEW dated row, so the report shows the
	  before/after trend over time.
	- Pair with the `apex-bulk-soql` skill: if the run shows SOQL/DML scaling with N,
	  bulkify first, then re‑profile to capture the improved row.
	- Reference template: `ManageBacklogControllerGovernorTest.cls`.
