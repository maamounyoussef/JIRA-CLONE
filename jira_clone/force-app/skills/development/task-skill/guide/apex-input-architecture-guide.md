---
name: apex-input-architecture-guide
activation:
  mode: required
  applies_when: >-
    a new Apex method/class is implemented for the functionality and that
    method takes parameters from the LWC
    (skip when no new server-side method is created, or the new method takes
    no arguments)
description: >
  BEFORE creating any new @AuraEnabled method, decide WHAT SHAPE its inputs
  take and HOW they are guarded at the controller boundary. This is the
  Apex-side INPUT guide — the companion to `apex-path-architecture-guide`,
  which decides where the classes live and how the layers connect.

  TRIGGER when a new server-side method needs to accept data from the LWC:
  "what parameters should this @AuraEnabled method take", "should I pass
  fields or a wrapper", "how do I validate the inputs".

  SKIP when no new Apex method is created, or the new method takes no
  arguments (a pure read with no parameters).
---

# Apex Input Architecture

Decides the **input side** of every new `@AuraEnabled` method: the parameter
shape the LWC sends, and the guard the controller runs before delegating to the
Service. Where the classes themselves live is decided separately in
`apex-path-architecture-guide`.

---

## Instructions

### Step 1 — Choose the parameter shape

- **2 or fewer scalar inputs** → pass them as primitive parameters
  (`String name, String projectId`).
- **3+ related inputs, or a nested/composite payload** → accept a single DTO
  parameter (`<Name>Dto dto`) with `@AuraEnabled` properties matching the
  shape the LWC sends.
- Type ids as `String` at the boundary; cast/validate inside.

### Step 2 — Guard inputs at the controller (input correctness only)

The controller owns **input correctness**, never business validation:

1. `String.isBlank(...)` for every required field → return
   `new APIResponse(false, '<field> is required')` on failure.
2. `DomainCorrectness.requireXExists(id)` for every referenced record.
3. Then delegate to the Service. Business rules belong in the Service, not here.

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

---

## Resources

- Where classes live & how layers connect: `apex-path-architecture-guide`.
- DTO conventions: `classes/domain/<Name>Dto.cls` (or `WorkflowConfigDTO.cls`).
- Guards: `classes/domain/DomainCorrectness.cls`.
- Envelope: `classes/guide/APIResponse.cls`.
