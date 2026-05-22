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
	whether to monitor it; if yes, you (1) generate a governor test method, (2) deploy
	the method and the new test class to the org, (3) run it, (4) parse the real
	metrics from the log, and (5) record them in the report file. The numbers in the
	report ALWAYS come from a real execution.

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
	Integer heapBefore    = Limits.getHeapSize();
	Integer cpuBefore     = Limits.getCpuTime();

	APIResponse res = <Class>.<method>(/* args */);

	Integer cpuUsed     = Limits.getCpuTime()       - cpuBefore;
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

	The single `APEX_METRIC|...` debug line is the machine‑readable payload parsed
	in Step 3 — keep that exact pipe‑delimited format. Do NOT use the human-readable
	label format (`CPU time (ms) : 131 / limit 10000`); that format cannot be parsed.

	### Step 3 — DEPLOY the method AND the new test class (before any run)

	A test cannot run against code that is not on the org. After the controller
	method is created/edited AND the governor test method is written, you MUST deploy
	both to the org **before** running anything. Order is non‑negotiable:
	**create/edit method → write test method → DEPLOY → run test.**

	Deploy the whole classes directory so the controller method and its new test
	class go up together (the new test class is included here — never run the test
	without deploying it first):

	```
	sf project deploy start -d force-app/main/default/classes
	```

	Confirm the deploy succeeded (status `Succeeded`, the `<Class>GovernorTest` class
	listed in the deployed components) before continuing. If the deploy fails (compile
	error, missing field, etc.), fix the cause and redeploy — do NOT proceed to the
	run until the method and test class are both deployed.

	### Step 4 — RUN the test and parse the real result

	Only after the deploy in Step 3 has succeeded, run only this test, capturing the
	debug log:

	```
	sf apex run test --tests <Class>GovernorTest.<testMethod> \
	    --result-format human --code-coverage --wait 10
	```

	Then locate the most recent debug log with the helper script (it returns the
	newest `*.log` path, the equivalent of `ls -t | tail -1`):

	```
	node scripts/latest-debug-log.js
	```

	Read that log and find the **one line** that starts with `APEX_METRIC|`. You can
	have the script print the log directly and scan its output:

	```
	node scripts/latest-debug-log.js --show
	```

	The line looks exactly like this (values will differ):

	```
	USER_DEBUG|[N]|DEBUG|APEX_METRIC|ManageBacklogController.deleteTickets|N=24|CPU=131|HEAP=1015|SOQL=26|DMLROWS=25|DMLSTMT=2
	```

	**Parse it by splitting on `|` and reading each segment by position/prefix:**

	| Pipe segment | Content | Extract as |
	|---|---|---|
	| `[4]` | `ManageBacklogController.deleteTickets` | `Class.Method` |
	| `[5]` | `N=24` | strip `N=` → `24` = **N (input)** |
	| `[6]` | `CPU=131` | strip `CPU=` → `131` = **CPU ms** |
	| `[7]` | `HEAP=1015` | strip `HEAP=` → `1015` = **Heap bytes** |
	| `[8]` | `SOQL=26` | strip `SOQL=` → `26` = **SOQL count** |
	| `[9]` | `DMLROWS=25` | strip `DMLROWS=` → `25` = **DML rows** |
	| `[10]` | `DMLSTMT=2` | strip `DMLSTMT=` → `2` = **DML stmts** |

	If the log contains the human-readable label format instead
	(`CPU time (ms) : 131 / limit 10000`) it means the test class is using the wrong
	debug format — **stop, fix the `System.debug` line in the test to emit
	`APEX_METRIC|...`**, redeploy, and re-run. Never parse the label format; it is
	not the source of truth.

	If the test fails, fix the cause (often a missing required field or an
	uninitialized rollup) and re-run — do not record numbers from a failed run.

	### Step 5 — APPEND the report row via the script

	Target file: `docs/apex-method-report.md`. Do **not** hand‑edit the table — use the
	helper script, which finds the table by its header and appends exactly one row
	(the Date column is generated automatically, today, local time):

	```
	node scripts/append_apex_report_row.js \
	    --report ./docs/apex-method-report.md \
	    --row "<Class.Method>|<N>|<CPU>|<HEAP>|<SOQL>|<DMLROWS>|<DMLSTMT>|<testMethodName>"
	```

	**Build the `--row` string from the values parsed in Step 3**, in this exact
	pipe order (no Date — the script adds it):

	```
	<Class.Method seg[4]>|<N seg[5]>|<CPU seg[6]>|<HEAP seg[7]>|<SOQL seg[8]>|<DMLROWS seg[9]>|<DMLSTMT seg[10]>|<testMethodName>
	```

	Concrete example (from the metric line above):

	```
	node scripts/append_apex_report_row.js \
	    --report ./docs/apex-method-report.md \
	    --row "ManageBacklogController.deleteTickets|24|131|1015|26|25|2|measureDeleteTicketsGovernorUsage"
	```

	which appends:

	```markdown
	| 2026-05-22 | ManageBacklogController.deleteTickets | 24 | 131 | 1015 | 26 | 25 | 2 | measureDeleteTicketsGovernorUsage |
	```

	If `docs/apex-method-report.md` does not yet exist, create it first with the
	header block below (the script only appends rows; it does not create the file),
	then run the script:

	```markdown
	# Apex Method Performance Report

	Governor-limit metrics captured from real test runs via the
	`apex-method-monitor` skill. Each row is one measured execution.

	| Date | Class.Method | N (input) | CPU (ms) | Heap (bytes) | SOQL | DML rows | DML stmts | Test method |
	|------|--------------|----------:|---------:|-------------:|-----:|---------:|----------:|-------------|
	```

	After appending, confirm the row that was written and flag any value approaching
	its governor limit:

	| Metric | Flag when |
	|---|---|
	| SOQL | > 80 (80 % of 100 limit) |
	| CPU ms | > 8 000 (80 % of 10 000 limit) |
	| Heap bytes | > 4 800 000 (80 % of 6 000 000 limit) |
	| DML rows | > 8 000 (80 % of 10 000 limit) |
	| DML stmts | > 120 (80 % of 150 limit) |

---

## NOTES

	- Numbers are never estimated or copied between methods — always from a fresh run.
	- Re‑profiling after an optimization adds a NEW dated row, so the report shows the
	  before/after trend over time.
	- Pair with the `apex-bulk-soql` skill: if the run shows SOQL/DML scaling with N,
	  bulkify first, then re‑profile to capture the improved row.
	- Reference template: `ManageBacklogControllerGovernorTest.cls`.