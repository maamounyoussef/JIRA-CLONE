# Object Validation Reference — LWC & Apex

All required fields and data types for every custom Salesforce object.
Use this as the source of truth for client-side (LWC) and server-side (Apex) validation.

---

## EpicLink__c

| Field API Name | Label | Type | Required |
|---|---|---|---|
| Epic__c | Epic | Lookup → Epic__c | YES |
| Ticket__c | Ticket | Lookup → Ticket__c | YES |
| IsActive__c | Is Active | Checkbox | no |
| Type__c | Type | Text(50) | true |

---

## Epic__c
for lwc 
| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |
| Summary__c | Summary | Text(255) | YES |
| CreatedAt__c | Created At | DateTime | no |
| Description__c | Description | TextArea | no |
| EndDate__c | End Date | DateTime | no |
| StartDate__c | Start Date | DateTime | no |
| UpdatedAt__c | Updated At | DateTime | no |
for apex and store
| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |
| Summary__c | Summary | Text(255) | YES |
| CreatedAt__c | Created At | DateTime | yes |
| Description__c | Description | TextArea | no |
| EndDate__c | End Date | DateTime | no |
| StartDate__c | Start Date | DateTime | no |
| UpdatedAt__c | Updated At | DateTime | yes |
---

## ProjectMember__c

| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |
| RecordStatus__c | Record Status | Text(100) | no |
| User__c | User | Lookup → User | yes | // just required for apex

---

## Project__c

| Field API Name | Label | Type | Required |
|---|---|---|---|
| Name | Name (standard) | Text | YES (standard) |

> No custom required fields. Standard `Name` field only.

---

## Sprint__c
for lwc : 
| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |
| Duration__c | Duration | Number(3, 0) | yes |
| Goal__c | Goal | TextArea | yes |
| RecordStatus__c | Record Status | Text(100) | no |
| StartDate__c | Start Date | Date | no |

for apex and store : 
| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |
| Duration__c | Duration | Number(3, 0) | yes |
| Goal__c | Goal | TextArea | yes |
| RecordStatus__c | Record Status | Text(100) | yes |
| StartDate__c | Start Date | Date | no |
---

## Status__c

| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |

> Standard `Name` field also required.

---

## Subtask__c

| Field API Name | Label | Type | Required |
|---|---|---|---|
| Summary__c | Summary | Text(255) | YES |
| Ticket__c | Ticket | Lookup → Ticket__c | YES |
| Assignee__c | Assignee | Lookup → ProjectMember__c | no |
| CurrentState__c | Current State | Lookup → Status__c | no |
| Description__c | Description | TextArea | no |
| RecordStatus__c | Record Status | Text(100) | no |
| StartDate__c | Start Date | DateTime | no |
| StoryPoint__c | Story Point | Number(2, 0) | no |

---

## TicketLink__c

for lwc:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| LinkedFromTicket__c | Linked From Ticket | Lookup → Ticket__c | YES |
| LinkedToTicket__c | Linked To Ticket | Lookup → Ticket__c | YES |
| RecordStatus__c | Record Status | Text(100) | no |
| Type__c | Type | Picklist | YES |

for apex and store:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| LinkedFromTicket__c | Linked From Ticket | Lookup → Ticket__c | YES |
| LinkedToTicket__c | Linked To Ticket | Lookup → Ticket__c | YES |
| RecordStatus__c | Record Status | Text(100) | YES |
| Type__c | Type | Picklist | YES |

**Type__c picklist values:** Blocks · Relates To · Duplicates · Depends On

---

## TicketType__c

for lwc:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| RecordStatus__c | RecordStatus | TextArea | no |
| Workflow__c | Workflow | Lookup → Workflow__c | YES |
| Description__c | Description | TextArea | YES |
| IconUrl__c | Icon URL | Text(255) | no |
| Project__c | Project | Lookup → Project__c | YES |

for apex and store : 
| Field API Name | Label | Type | Required |
|---|---|---|---|
| RecordStatus__c | RecordStatus | TextArea | YES |
| Workflow__c | Workflow | Lookup → Workflow__c | YES |
| Description__c | Description | TextArea | YES |
| IconUrl__c | Icon URL | Text(255) | YES |
| Project__c | Project | Lookup → Project__c | YES |

---

## Ticket__c
for lwc : 
| Field API Name | Label | Type | Required |
|---|---|---|---|
| CurrentState__c | Current State | Lookup → Status__c | YES |
| Summary__c | Summary | Text(255) | YES |
| AssignedTo__c | Assigned To | Lookup → ProjectMember__c | no |
| Creator__c | Creator | Lookup → ProjectMember__c | no |
| Description__c | Description | TextArea | no |
| EndDate__c | End Date | DateTime | no |
| Epic__c | Epic | Lookup → Epic__c | no |
| Priority__c | Priority | Picklist | no |
| RecordStatus__c | Record Status | Text(100) | no |
| Sprint__c | Sprint | Lookup → Sprint__c | no |
| StartDate__c | Start Date | DateTime | no |
| StoryPoint__c | Story Point | Number(2, 0) | no |
| Ticket_Type__c | Type | Lookup → TicketType__c | no |

for apex and store
| Field API Name | Label | Type | Required |
|---|---|---|---|
| CurrentState__c | Current State | Lookup → Status__c | YES |
| Summary__c | Summary | Text(255) | YES |
| AssignedTo__c | Assigned To | Lookup → ProjectMember__c | no |
| Creator__c | Creator | Lookup → ProjectMember__c | yes | // get the userid using apex method and get the projectmember id based on this user
| Description__c | Description | TextArea | yes |
| EndDate__c | End Date | DateTime | no |
| Epic__c | Epic | Lookup → Epic__c | no |
| Priority__c | Priority | Picklist | yes |
| RecordStatus__c | Record Status | Text(100) | yes |
| Sprint__c | Sprint | Lookup → Sprint__c | no |
| StartDate__c | Start Date | DateTime | no |
| StoryPoint__c | Story Point | Number(2, 0) | no |
| Ticket_Type__c | Type | Lookup → TicketType__c | yes |

**Priority__c picklist values:** Critical · High · Medium · Low

---

## ValidationRule__c
for lwc:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| WorkflowTransition__c | Workflow Transition | Lookup → WorkflowTransition__c | YES |
| RecordStatus__c | Record Status | Text(100) | no |
| TicketField__c | Ticket Field | Text(100) | yes |
| Type__c | Type | Picklist | yes |

for apex and store:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| WorkflowTransition__c | Workflow Transition | Lookup → WorkflowTransition__c | YES |
| RecordStatus__c | Record Status | Text(100) | yes |
| TicketField__c | Ticket Field | Text(100) | yes |
| Type__c | Type | Picklist | yes |

**Type__c picklist values:** Not Equals

---

## WorkflowTransition__c
for lwc:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| FromStatus__c | From Status | Lookup → Status__c | YES |
| ToStatus__c | To Status | Lookup → Status__c | YES |
| Workflow__c | Workflow | Lookup → Workflow__c | YES |
| RecordStatus__c | Record Status | Text(100) | yes |

for apex and store:
| Field API Name | Label | Type | Required |
|---|---|---|---|
| FromStatus__c | From Status | Lookup → Status__c | YES |
| ToStatus__c | To Status | Lookup → Status__c | YES |
| Workflow__c | Workflow | Lookup → Workflow__c | YES |
| RecordStatus__c | Record Status | Text(100) | yes |

---

## Workflow__c

| Field API Name | Label | Type | Required |
|---|---|---|---|
| Project__c | Project | Lookup → Project__c | YES |

> Standard `Name` field also required.

---

## Quick Reference — Required Fields Only

| Object | Required Fields |
|---|---|
| EpicLink__c | Epic__c, Ticket__c |
| Epic__c | Project__c, Summary__c |
| ProjectMember__c | Project__c |
| Project__c | Name (standard) |
| Sprint__c | Project__c |
| Status__c | Project__c |
| Subtask__c | Summary__c, Ticket__c |
| TicketLink__c | LinkedFromTicket__c, LinkedToTicket__c, RecordStatus__c, Type__c |
| TicketType__c | RecordStatus__c, Workflow__c |
| Ticket__c | CurrentState__c, Summary__c |
| ValidationRule__c | WorkflowTransition__c, TicketField__c, Type__c |
| WorkflowTransition__c | FromStatus__c, ToStatus__c, Workflow__c |
| Workflow__c | Project__c |

---

## Data Type Legend

| Type | Notes |
|---|---|
| Text(n) | Max length n characters |
| TextArea | Long text, no length enforced |
| DateTime | Date + time value |
| Date | Date only |
| Number(p, s) | p = total digits, s = decimal places |
| Checkbox | Boolean true/false |
| Picklist | Single-select from defined values |
| Lookup → X | Foreign key reference to object X |
