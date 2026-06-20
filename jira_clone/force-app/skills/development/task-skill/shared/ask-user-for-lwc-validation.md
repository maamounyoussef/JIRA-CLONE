---
name: ask-user-for-lwc-validation
description: >
  Shared interview sub-step for the LWC "Validation rules" question. Asks the
  user whether client-side validation must run before any event dispatch / Apex
  call; on "yes", points them at OBJECT_VALIDATION_LWC_APEX.md (the LWC table)
  as the required-field source of truth.
---


## Step 0 — gate question: is validation needed?

> *"Does this component need any validation before it dispatches an event /
> calls Apex?"*
> - *Yes*
> - *No*

### No → record "no validations" and move on

Do not create a `<name>Validator.js`, do not add any inline checks. Return to
the calling skill's next question.

### Yes → ask the user which validations, then anchor to the reference

Ask the user to list the validations to enforce. The user provides them — do not
suggest or fill in rules they did not state.

When the user's validations include **required fields** (a field that must be
present before dispatch), the message strings and which-fields-are-required come
from **[OBJECT_VALIDATION_LWC_APEX.md](../../../../../OBJECT_VALIDATION_LWC_APEX.md)** —
read the object's **"for lwc"** table (not "for apex and store"), because this is
the client/form layer. Tell the user explicitly:

> *"Required-field validations for this object are defined in
> `OBJECT_VALIDATION_LWC_APEX.md` under the object's **for lwc** table. I'll use
> that table for the required set and message strings; please confirm any extra
> (format / cross-field / business) rules beyond required fields."*

