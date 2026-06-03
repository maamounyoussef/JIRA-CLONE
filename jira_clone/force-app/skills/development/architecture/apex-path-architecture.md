---
name: apex-architecture
description: >
  BEFORE creating or scaffolding any new Apex that backs a Lightning Web
  Component, decide WHERE every class goes and HOW the layers connect
  (Controller → APIResponse → Service → DomainCorrectness). This is the
  Apex-side architecture guide. The LWC layer that calls into it is defined
  separately in `lwc-architecture`.

  TRIGGER when the user asks "where should this Apex method live", "add a new
  @AuraEnabled method", "create a controller/service for X", "what's the right
  structure for the Apex behind this screen", or whenever a new UI component
  needs a new server-side method.

  SKIP when the work is a pure edit inside an existing class that does not change
  its architectural role (no new public method, no new object, no new layer).
---

# Apex Architecture

Places every new Apex class that backs an LWC inside the project's layered
architecture: a thin `@AuraEnabled` Controller returns an `APIResponse`
envelope, delegates business logic and SOQL/DML to a domain Service, and guards
preconditions through `DomainCorrectness`. Decide the layout BEFORE any code is
written. The LWC layer that imports these methods is defined in
`lwc-architecture`.

---

## Instructions

### Step 1 — Resolve the Apex side FIRST

When the work crosses layers (new UI needing new Apex), resolve the Apex side
FIRST so the LWC has a real method to import — never import a method you haven't
confirmed/created.

### Step 2 — Apply the Apex layer rules

**Controller — `classes/controller/<feature>/<Name>Controller.cls`**
- Thin orchestration only. Every public method is `@AuraEnabled`
  (`@AuraEnabled(cacheable=true)` for pure reads used by `@wire`).
- ALWAYS return `APIResponse`: `new APIResponse(true, 'msg', data)` on success,
  `new APIResponse(false, 'msg')` on failure.
- Wrap the body in try/catch; on `Exception ex` return
  `new APIResponse(false, 'Error ...: ' + ex.getMessage())`.
- Guard inputs: `String.isBlank(...)` checks, then
  `DomainCorrectness.requireXExists(id)` for every referenced record.
- Delegate real work to a Service. Do not put SOQL/DML business logic here.

```apex
@AuraEnabled
public static APIResponse createStatus(String name, String projectId) {
    try {
        if (String.isBlank(name)) return new APIResponse(false, 'name is required');
        if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
        DomainCorrectness.requireProjectExists(projectId);
        Status__c status = StatusService.createStatus(name, projectId);
        return new APIResponse(true, 'Status created successfully', status);
    } catch (Exception ex) {
        return new APIResponse(false, 'Error creating status: ' + ex.getMessage());
    }
}
```

**Service — `classes/domain/<Name>Service.cls`**
- `public with sharing`. Holds the SOQL/DML and business rules.
- Throws `ServiceException` (never bare `Exception`) on failure.
- Static methods named for the use case (`createStatus`, `loadStatuses`,
  `findStatus`). One Service per domain object.

**Guards — `classes/domain/DomainCorrectness.cls`**
- `requireXExists(id)` returns the record or throws `ServiceException`.
- `requireOptionalXExists(id)` no-ops on blank, else asserts. Reuse these;
  add a new `requireXExists` here when introducing a new object.

**DTOs — `classes/domain/<Name>Dto.cls` (or `WorkflowConfigDTO.cls`)**
- Use a DTO when a response is a composite/nested shape (not a single SObject),
  with `@AuraEnabled` properties matching the client shape the LWC expects.

**Shared — `classes/guide/`**
- `APIResponse` (envelope), `ServiceException` (only thrown type), plus
  enums/utils/constants. Don't duplicate these per feature.

### Step 3 — Creating NEW Apex for a new component

1. Method belongs in the feature's existing `<Name>Controller`, or a new one
   under `controller/<feature>/`.
2. If business logic/DML is new, add it to the matching `<Name>Service`
   (create the Service if the object has none).
3. Add `requireXExists` guards to `DomainCorrectness` for any new object.
4. Add a test class alongside (`<Name>ControllerTest.cls`) — every controller
   in this project ships with a `*Test` class.

---

## Resources

### The Apex layer at a glance

Data flows in one direction per request and back as a single wrapped response:

```
                │ @salesforce/apex/<Controller>.<method>   (from lwc-architecture)
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│  APEX LAYER                                                            │
│                                                                        │
│   controller/<feature>/<Name>Controller.cls   (thin, @AuraEnabled)    │
│     • returns APIResponse(success, message, data) ALWAYS              │
│     • wraps everything in try/catch                                    │
│     • validates preconditions via DomainCorrectness.requireXExists()   │
│     • delegates business logic to a Service                            │
│                          │                                             │
│                          ▼                                             │
│   domain/<Name>Service.cls    (business logic + SOQL/DML)             │
│     • throws ServiceException on failure                               │
│   domain/DomainCorrectness.cls (existence / precondition guards)       │
│   domain/<Name>Dto.cls / WorkflowConfigDTO.cls (composite shapes)      │
│                                                                        │
│   shared/APIResponse.cls       (the response envelope)                 │
│   shared/ServiceException.cls  (the only exception services throw)     │
│   shared/<...>Enum/Util/Constants.cls                                  │
└──────────────────────────────────────────────────────────────────────┘
```

### Reference implementations

Copy from these when scaffolding:
- Controller: `classes/controller/managebacklog/ManageBacklogController.cls`
- Service: `classes/domain/StatusService.cls`, `classes/domain/TicketService.cls`
- Guards: `classes/domain/DomainCorrectness.cls`
- Envelope: `classes/guide/APIResponse.cls`

### Naming & folder conventions

- Apex controllers grouped by feature folder: `controller/<feature>/`.
- Services, guards, DTOs, trigger handlers live flat in `domain/`.
- Cross-cutting types live in `shared/`.

---
