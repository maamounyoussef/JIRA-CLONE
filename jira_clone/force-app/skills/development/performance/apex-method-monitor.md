---
name: apex-method-monitor
description: >
  Profiles an Apex controller method with a real governor-limit test and
  records the result in `docs/apex-method-report.md`. It generates a test
  that wraps the method in `Test.startTest()`/`stopTest()`, snapshots
  `Limits.getCpuTime()`, `getHeapSize()`, `getQueries()`, `getDmlRows()`,
  and `getDmlStatements()` around the call, deploys, runs the test against
  the org, parses the pipe-delimited metric line from the debug log, and
  appends one dated row to the report. Every number comes from an actual
  test run — never estimated — so re-profiling after an optimization adds
  a new row instead of overwriting, and the report keeps the before/after
  trend.

  Use this after creating or editing any `@AuraEnabled` method in
  `classes/controller/**` whose body does SOQL, SOSL, or DML. It asks
  before running, via the interactive `AskUserQuestion` tool, so it never
  profiles without consent. Skip it for pure-computation methods that
  touch no data, and for methods you have already declined to profile in
  the current session.
---

# Apex Method Monitor

Measures real governor-limit usage for every data-touching Apex controller method
and appends the results to `docs/apex-method-report.md`. Numbers always come from
an actual test run — never estimated.

---

## Instructions

### Step 1 — Ask the user

After the controller method is written or edited, present the following choice using
the interactive **`AskUserQuestion`** tool (not plain text):

- **header**: `Monitor method`
- **question**: `Create a monitoring report for <Class>.<method>? I'll generate a governor-limit test, run it, and record CPU / Heap / SOQL / DML-rows / DML-statements in docs/apex-method-report.md.`
- **multiSelect**: `false`
- **options**:
  1. **Yes, generate & run** — Generate the governor test, run it, and append the real metrics to the report.
  2. **No, skip** — Don't profile this method.

If the user selects **No, skip** → stop immediately. If **Yes** → continue.

---

### Step 2 — Generate the test method

Add a test method to `classes/controller/<feature>/<Class>GovernorTest.cls` (create
the file if it does not exist, using `ManageBacklogControllerGovernorTest.cls` as the
template). The method must:

1. Build all prerequisite data with every required field set per
   `OBJECT_VALIDATION_LWC_APEX.md` (use the "for apex and store" column).
2. Size the input to the method's realistic bulk case (e.g. validator cap or a
   representative N). State N in the report.
3. Wrap only the method call — not the setup — between `Test.startTest()` /
   `Test.stopTest()` so governor counters are isolated:

```apex
Test.startTest();
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

> **Critical:** the `APEX_METRIC|...` line must use exactly this pipe-delimited
> format — it is the machine-readable payload parsed in Step 4. Do **not** use the
> human-readable label format (`CPU time (ms) : 131 / limit 10000`); that format
> cannot be parsed.

---

### Step 3 — Deploy before running

A test cannot run against code that is not on the org. Deploy the entire `classes`
directory so the controller method and its new test class go up together:

```bash
sf project deploy start -d force-app/main/default/classes
```

Confirm the deploy status is `Succeeded` and that `<Class>GovernorTest` appears in
the deployed components list before continuing. If the deploy fails (compile error,
missing field, etc.), fix the cause and redeploy. **Never proceed to the run until
both files are deployed.**

---

### Step 4 — Run the test and parse the result

Only after a successful deploy, run just this test method and capture its debug log:

```bash
sf apex run test \
  --tests <Class>GovernorTest.<testMethod> \
  --result-format human \
  --code-coverage \
  --wait 10
```

Retrieve the most recent debug log:

```bash
node scripts/latest-debug-log.js --show
```

Scan the output for the **one line** that starts with `APEX_METRIC|`. It looks like:

```
USER_DEBUG|[N]|DEBUG|APEX_METRIC|ManageBacklogController.deleteTickets|N=24|CPU=131|HEAP=1015|SOQL=26|DMLROWS=25|DMLSTMT=2
```

Parse it by splitting on `|` and reading each segment by position:

| Pipe segment | Content | Extract as |
|---|---|---|
| `[4]` | `ManageBacklogController.deleteTickets` | `Class.Method` |
| `[5]` | `N=24` | strip `N=` → **N (input)** |
| `[6]` | `CPU=131` | strip `CPU=` → **CPU ms** |
| `[7]` | `HEAP=1015` | strip `HEAP=` → **Heap bytes** |
| `[8]` | `SOQL=26` | strip `SOQL=` → **SOQL count** |
| `[9]` | `DMLROWS=25` | strip `DMLROWS=` → **DML rows** |
| `[10]` | `DMLSTMT=2` | strip `DMLSTMT=` → **DML stmts** |

If the test fails, fix the cause (often a missing required field or an uninitialized
rollup) and re-run. Do not record numbers from a failed run.

---

### Step 5 — Append the report row

Use the helper script to append exactly one row to `docs/apex-method-report.md`
(the Date column is generated automatically):

```bash
node scripts/append_apex_report_row.js \
  --report ./docs/apex-method-report.md \
  --row "<Class.Method>|<N>|<CPU>|<HEAP>|<SOQL>|<DMLROWS>|<DMLSTMT>|<testMethodName>"
```

Build the `--row` string from the values parsed in Step 4, in this exact pipe order
(no Date — the script adds it):

```
<seg[4]>|<seg[5]>|<seg[6]>|<seg[7]>|<seg[8]>|<seg[9]>|<seg[10]>|<testMethodName>
```

After appending, confirm the row that was written and flag any value that approaches
its governor limit (see the **Optional Logic** section below).

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/latest-debug-log.js` | Returns the path of the newest `*.log` file; pass `--show` to print its contents |
| `scripts/append_apex_report_row.js` | Finds the report table by its header and appends one row with today's date |

---

## Resources

### Report file: `docs/apex-method-report.md`

If the file does not yet exist, create it with this header block before running the
append script (the script only appends rows; it does not create the file):

```markdown
# Apex Method Performance Report

Governor-limit metrics captured from real test runs via the
`apex-method-monitor` skill. Each row is one measured execution.

| Date | Class.Method | N (input) | CPU (ms) | Heap (bytes) | SOQL | DML rows | DML stmts | Test method |
|------|--------------|----------:|---------:|-------------:|-----:|---------:|----------:|-------------|
```

### Concrete example

Given the metric line parsed in Step 4:

```
USER_DEBUG|[42]|DEBUG|APEX_METRIC|ManageBacklogController.deleteTickets|N=24|CPU=131|HEAP=1015|SOQL=26|DMLROWS=25|DMLSTMT=2
```

The append call is:

```bash
node scripts/append_apex_report_row.js \
  --report ./docs/apex-method-report.md \
  --row "ManageBacklogController.deleteTickets|24|131|1015|26|25|2|measureDeleteTicketsGovernorUsage"
```

Which appends:

```markdown
| 2026-05-22 | ManageBacklogController.deleteTickets | 24 | 131 | 1015 | 26 | 25 | 2 | measureDeleteTicketsGovernorUsage |
```

### Reference template

`ManageBacklogControllerGovernorTest.cls` — use as the template when creating a new
`<Class>GovernorTest.cls`.

---

## Optional Logic

### Governor-limit warnings

After appending the row, flag any metric that exceeds 80% of its Salesforce limit:

| Metric | Flag when |
|---|---|
| SOQL queries | > 80 (80% of 100 limit) |
| CPU ms | > 8,000 (80% of 10,000 limit) |
| Heap bytes | > 4,800,000 (80% of 6,000,000 limit) |
| DML rows | > 8,000 (80% of 10,000 limit) |
| DML stmts | > 120 (80% of 150 limit) |

### Re-profiling after optimization

Re-running this skill after a performance fix appends a **new dated row** rather than
overwriting the old one, so the report captures the before/after trend over time.

### Integration with `apex-bulk-soql` skill

If the run shows SOQL or DML counts scaling with N (i.e. an N+1 pattern), bulkify
the method using the `apex-bulk-soql` skill first, then re-profile to capture the
improved row.