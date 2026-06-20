---
name: lwc-path-architecture-guide
activation:
  mode: required
  applies_when: always — settle LWC layering before any interview question
description: >
  Settles the LWC layering before any interview question: page (smart) vs child
  (presentation) split, principal state ownership, sidecar
  `<feature>Utils.js` / `<feature>Validator.js`, and the naming / event
  conventions (camelCase bundle, lowercase event names, `_`-prefixed
  presentation state bound via getters). Required guide for every LWC task-skill.
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
            APEX LAYER  (see apex-path-architecture-guide)
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