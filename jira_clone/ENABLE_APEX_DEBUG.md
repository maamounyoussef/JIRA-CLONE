## Enable Apex Debugging in VS Code (Replay & Live)

Two approaches:
- Replay Debugger (free): capture a debug log and replay it in VS Code. Breakpoints will stop when the log is replayed.
- Live Apex Debugger (requires Apex Debugger license): attach directly to the org and stop on breakpoints in real time.

### Replay Debugger (recommended if you don't have a license)

Prerequisites:
- Salesforce CLI installed and authenticated to the target org (`sfdx force:org:display -u <ORG_ALIAS>`)
- Salesforce Extensions for VS Code installed
- Set breakpoints in your Apex sources in VS Code

Steps:

1. Create a DebugLevel (one-time):

```bash
sfdx force:data:record:create -s DebugLevel -v "DeveloperName=ReplayDebugLevel MasterLabel=ReplayDebugLevel ApexCode=FINEST ApexProfiling=FINEST Callout=FINEST Database=FINEST System=FINEST Visualforce=FINEST Workflow=FINEST" -u <ORG_ALIAS>
```

2. Create a Trace Flag for your user (use Setup → Debug Logs → New or via CLI):

- GUI: Setup → Debug Logs → New → Traced Entity = your User → choose DebugLevel created above → set Expiration → Save

- CLI (get user id via SOQL then create TraceFlag):

```bash
# find your user id (replace email/username)
sfdx force:data:soql:query -q "SELECT Id FROM User WHERE Username='your.username@domain.com'" -u <ORG_ALIAS> -r csv

# create trace flag (replace <USER_ID> and <DEBUGLEVEL_ID>)
sfdx force:data:record:create -s TraceFlag -v "TracedEntityId=<USER_ID> DebugLevelId=<DEBUGLEVEL_ID> StartDate=2026-04-15T00:00:00.000Z ExpirationDate=2026-04-16T00:00:00.000Z" -u <ORG_ALIAS>
```

3. Trigger the Apex code you want to debug (execute anonymous, run test, or use the UI).

4. Pull the debug log and save into the workspace `apex_logs` folder:

```bash
sfdx force:apex:log:list -u <ORG_ALIAS>
sfdx force:apex:log:get -i <LOG_ID> -u <ORG_ALIAS> -d ./apex_logs
# the downloaded file will be named like 00D..._SomeLog.txt; rename it to replayDebugLog.txt or update .vscode/launch.json
```

5. In VS Code: open Run view, choose **Launch Apex Replay Debugger**, then start. The debugger will replay the log and stop at breakpoints.

### Live Apex Debugger (optional, requires license)

1. Confirm your org has Apex Debugger enabled and your user has the required permission set.
2. In VS Code Command Palette run `SFDX: Start Apex Debugger Session` (or the Start/Launch Apex Debugger command from the Salesforce extensions) to create a debug session.
3. Run `SFDX: Launch Apex Debugger` to attach the VS Code debugger, then trigger the transaction in Salesforce; breakpoints will stop live.

### Notes

- Make sure breakpoints are set before starting the debugger.
- If using the Replay Debugger, the log must include the execution you're interested in.
- If anything fails, copy the exact CLI output and I can help troubleshoot.

Files added:
- [.vscode/launch.json](.vscode/launch.json)