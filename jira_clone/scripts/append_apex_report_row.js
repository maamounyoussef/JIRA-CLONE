#!/usr/bin/env node
/**
 * append_apex_report_row.js
 *
 * Appends one measurement row to the Apex Method Performance Report markdown table.
 *
 * Usage:
 *   node append_apex_report_row.js \
 *     --report  ./apex-method-report.md \
 *     --row     "ManageBacklogController.deleteTickets|24|272|1079|49|25|2|measureDeleteTicketsGovernorUsage"
 *
 * Row string format (pipe-separated, positional):
 *   <Class.Method> | <N> | <CPU_ms> | <Heap_bytes> | <SOQL> | <DML_rows> | <DML_stmts> | <Test_method>
 *
 * Any field left empty (e.g. "foo||bar") is stored as null → rendered as "—" in the table.
 * Date is generated automatically (today, YYYY-MM-DD, local time).
 *
 * The script locates the markdown table by its header line and appends a new row
 * immediately after the last existing data row.
 */

const fs   = require("fs");
const path = require("path");

// ── CLI parsing ──────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === "--report" && argv[i + 1]) { args.report = argv[++i]; }
    else if (argv[i] === "--row"    && argv[i + 1]) { args.row    = argv[++i]; }
  }
  return args;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function todayISO() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/**
 * Parse the pipe-separated row string into an object.
 * Fields (in order): class_method, n, cpu_ms, heap_bytes, soql, dml_rows, dml_stmts, test_method
 */
function parseRowString(rowStr) {
  const FIELDS = [
    "class_method",
    "n",
    "cpu_ms",
    "heap_bytes",
    "soql",
    "dml_rows",
    "dml_stmts",
    "test_method",
  ];

  const parts = rowStr.split("|").map(s => s.trim());

  const row = {};
  FIELDS.forEach((field, idx) => {
    const val = parts[idx];
    row[field] = (val === undefined || val === "") ? null : val;
  });

  return row;
}

/**
 * Render a row object as a markdown table row.
 * Null values become "—".
 */
function renderTableRow(date, row) {
  const display = v => (v === null ? "—" : v);
  return `| ${date} | ${display(row.class_method)} | ${display(row.n)} | ${display(row.cpu_ms)} | ${display(row.heap_bytes)} | ${display(row.soql)} | ${display(row.dml_rows)} | ${display(row.dml_stmts)} | ${display(row.test_method)} |`;
}

/**
 * Find the table in the markdown content and append a new row.
 * The table is identified by the canonical header line that contains "Class.Method".
 */
function appendRowToTable(mdContent, newRow) {
  const lines = mdContent.split("\n");

  // Find the header line index
  const headerIdx = lines.findIndex(l => l.includes("Class.Method") && l.startsWith("|"));
  if (headerIdx === -1) {
    throw new Error('Could not find the table header line containing "Class.Method".');
  }

  // Find the last table data row (skip separator line)
  let lastTableIdx = headerIdx + 1; // separator line
  for (let i = headerIdx + 2; i < lines.length; i++) {
    if (lines[i].startsWith("|")) {
      lastTableIdx = i;
    } else {
      break;
    }
  }

  // Insert the new row after the last table row
  lines.splice(lastTableIdx + 1, 0, newRow);
  return lines.join("\n");
}

// ── Main ─────────────────────────────────────────────────────────────────────

function main() {
  const args = parseArgs(process.argv);

  if (!args.report) {
    console.error("Error: --report <path-to-md-file> is required.");
    process.exit(1);
  }
  if (!args.row) {
    console.error("Error: --row <pipe-separated-values> is required.");
    process.exit(1);
  }

  const reportPath = path.resolve(args.report);

  if (!fs.existsSync(reportPath)) {
    console.error(`Error: Report file not found: ${reportPath}`);
    process.exit(1);
  }

  const date    = todayISO();
  const rowData = parseRowString(args.row);
  const mdRow   = renderTableRow(date, rowData);

  console.log("\nParsed row:");
  console.log("  Date        :", date);
  Object.entries(rowData).forEach(([k, v]) =>
    console.log(`  ${k.padEnd(12)}: ${v === null ? "(null → —)" : v}`)
  );
  console.log("\nMarkdown row to append:");
  console.log(" ", mdRow);

  const original = fs.readFileSync(reportPath, "utf8");
  const updated  = appendRowToTable(original, mdRow);

  fs.writeFileSync(reportPath, updated, "utf8");
  console.log(`\n✓ Row appended to ${reportPath}`);
}

main();