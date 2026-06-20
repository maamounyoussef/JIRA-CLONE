#!/usr/bin/env node
/**
 * latest-debug-log.js
 *
 * Find the most recent Salesforce debug log in .sfdx/tools/debug/logs.
 * Equivalent of `ls -t | tail -1` for the SFDX debug logs folder: returns the
 * single newest *.log file (by mtime).
 *
 * Usage:
 *   node latest-debug-log.js                 # prints the latest log's path
 *   node latest-debug-log.js --show          # prints the whole log
 *   node latest-debug-log.js --tail 50       # prints the last 50 lines
 *   node latest-debug-log.js --dir <path>    # override the logs directory
 */

const fs   = require("fs");
const path = require("path");

// ── CLI parsing ──────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const args = { show: false, tail: 0, dir: null };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === "--show") { args.show = true; }
    else if (argv[i] === "--tail" && argv[i + 1]) { args.tail = parseInt(argv[++i], 10) || 0; }
    else if (argv[i] === "--dir"  && argv[i + 1]) { args.dir  = argv[++i]; }
  }
  return args;
}

// ── Main ─────────────────────────────────────────────────────────────────────

function main() {
  const args = parseArgs(process.argv);

  const logDir = path.resolve(
    args.dir || path.join(__dirname, "..", ".sfdx", "tools", "debug", "logs")
  );

  if (!fs.existsSync(logDir)) {
    console.error(`Error: Log directory not found: ${logDir}`);
    process.exit(1);
  }

  const logs = fs.readdirSync(logDir)
    .filter(f => f.endsWith(".log"))
    .map(f => {
      const full = path.join(logDir, f);
      return { full, mtime: fs.statSync(full).mtimeMs };
    })
    .sort((a, b) => b.mtime - a.mtime);

  if (logs.length === 0) {
    console.error(`Error: No .log files found in ${logDir}`);
    process.exit(1);
  }

  const latest = logs[0].full;

  if (args.tail > 0) {
    const lines = fs.readFileSync(latest, "utf8").split("\n");
    console.log(lines.slice(-args.tail).join("\n"));
  } else if (args.show) {
    console.log(fs.readFileSync(latest, "utf8"));
  } else {
    console.log(latest);
  }
}

main();
