---
name: lwc-architecture
description: >
  
---
## Resources

### The LWC layer at a glance

```
┌──────────────────────────────────────────────────────────────────────┐
│  LWC LAYER                                                             │
│                                                                        │
│   PAGE component (smart)            CHILD components (presentation)    │
│   - owns principal state            - receive data via @api           │
│   - calls Apex (imperative/@wire)   - own local presentation state    │
│   - handles child events            - dispatch CustomEvents up         │
│   - sidecar: <feature>Utils.js,     - NEVER call Apex                  │
│     <feature>Validator.js           - NEVER mutate @api                │
└───────────────┬────────────────────────────────────────────────────────┘
                │ @salesforce/apex/<Controller>.<method>
                ▼
            APEX LAYER  (see apex-architecture)
```

### Reference implementations

Copy from these when scaffolding:
- Page: `lwc/manageBacklog/`

### Naming & folder conventions

- LWC bundle folder = camelCase feature name (`manageWorkflow`); referenced in
  markup as `c-manage-workflow`.
- Sidecars: `<feature>Utils.js`, `<feature>Validator.js` inside the bundle.
- Event names: lowercase, no camelCase, no hyphens (`ticketsummaryupdate`).
- LWC local/presentation state fields: `_`-prefixed; bound via getters.

---