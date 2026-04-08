# Manage Workflow LWC Components

This directory contains Lightning Web Components for managing Salesforce Workflow configurations.

## Components

### 1. manageWorkflowContainer
**Purpose:** Main container component that orchestrates the workflow management experience.

**Features:**
- Displays the form component for initial selection
- Manages navigation between form and workflow manager
- Handles component lifecycle

**Properties:**
- None (uses internal state)

---

### 2. manageWorkflowForm
**Purpose:** Form component for selecting Ticket Type and Project.

**Features:**
- Ticket Type dropdown selection
- Project dropdown selection
- Form validation
- Reset functionality

**Events:**
- `launchworkflow` - Fired when user clicks "Launch Workflow Manager" with detail:
  ```javascript
  {
      ticketType: String,
      projectId: String
  }
  ```

**Methods:**
- `loadTicketTypes()` - Loads available ticket types
- `loadProjects()` - Loads available projects
- `handleLaunchWorkflow()` - Validates and launches workflow manager
- `handleReset()` - Clears form fields

---

### 3. manageWorkflow
**Purpose:** Main workflow configuration manager component.

**Features:**
- Displays workflow diagram with status transitions (visual representation)
- Sidebar showing pending and active items
- Add Validation Rules to transitions
- Update/Delete Validation Rules
- Add new Workflow Transitions
- Activate Validation Rules (pending → active)
- Activate Workflow Transitions (pending → active)
- Bulk Update Workflow to activate all pending records

**Events:**
- None (self-contained)

**Methods:**

#### Data Loading
- `loadWorkflow()` - Fetches workflow configuration from controller

#### Validation Rule Operations
- `handleAddValidationRule()` - Creates new validation rule
- `handleDeleteValidationRule()` - Soft deletes validation rule
- `handleActivateValidationRule()` - Activates pending validation rule
- `openAddValidationRuleModal()` - Opens add validation rule dialog
- `closeAddValidationRuleModal()` - Closes add validation rule dialog

#### Workflow Transition Operations
- `handleAddWorkflowTransition()` - Creates new workflow transition
- `handleActivateTransition()` - Activates pending transition
- `openAddTransitionModal()` - Opens add transition dialog
- `closeAddTransitionModal()` - Closes add transition dialog

#### Workflow Management
- `handleUpdateWorkflow()` - Final bulk update to activate all pending records
- `handleSelectTransition()` - Selects a transition for editing

**Getters:**
- `statusOptions` - Returns Status combobox options
- `ticketFieldOptions` - Returns Ticket Field combobox options
- `validationTypeOptions` - Returns Validation Type combobox options
- `pendingTransitions` - Filters pending workflow transitions
- `activeTransitions` - Filters active workflow transitions
- `pendingValidationRules` - Filters pending validation rules for selected transition
- `activeValidationRules` - Filters active validation rules for selected transition

---

## Component Architecture

```
manageWorkflowContainer
├── manageWorkflowForm
│   ├── Input: ticketTypeOptions, projectOptions
│   └── Output: launchworkflow event
│
└── manageWorkflow
    ├── Diagram Display (Workflow Transitions)
    ├── Sidebar
    │   ├── Pending Transitions
    │   └── Validation Rules
    │       ├── Pending
    │       └── Active
    ├── Modals
    │   ├── Add Validation Rule Modal
    │   └── Add Transition Modal
    └── Action Buttons
        ├── Add Validation Rule
        ├── Activate Rules/Transitions
        ├── Delete Rules
        ├── Add Transition
        └── Update Workflow
```

---

## Apex Integration

These components consume the following Apex methods from `WorkflowController`:

- `getWorkflow(workflowId)` - Returns WorkflowConfigDTO wrapped in APIResponse
- `getProjectStatuses(projectId)` - Returns List<Status__c> wrapped in APIResponse
- `addValidationRule(...)` - Creates validation rule
- `updateValidationRule(...)` - Updates validation rule
- `deleteValidationRule(...)` - Soft deletes validation rule
- `addWorkflowTransition(...)` - Creates workflow transition
- `activateValidationRule(...)` - Activates validation rule
- `activateWorkflowTransition(...)` - Activates workflow transition
- `updateWorkflow(...)` - Final workflow update

---

## User Flows

### Flow 1: Access Workflow Manager
1. User opens `manageWorkflowContainer` component
2. Sees `manageWorkflowForm` with dropdown selectors
3. Selects Ticket Type and Project
4. Clicks "Launch Workflow Manager" button
5. `manageWorkflow` component loads with workflow configuration

### Flow 2: Add Validation Rule
1. User selects a transition from diagram
2. Pending validation rules sidebar appears for that transition
3. Clicks "Add Validation Rule" button
4. Modal appears with field and type selectors
5. Selects field and validation type
6. Clicks "Add Rule" to create
7. Rule appears in pending section with "Activate" and "Delete" options

### Flow 3: Activate Validation Rule
1. User sees pending validation rule in sidebar
2. Clicks "Activate" button on the rule
3. Confirmation dialog appears
4. Clicks "OK" to confirm
5. Rule moves from pending to active section

### Flow 4: Add Workflow Transition
1. User clicks "Add Transition" button in diagram
2. Modal appears with transition form
3. Enters transition name
4. Selects "From Status" and "To Status"
5. Clicks "Create Transition"
6. New pending transition appears in diagram

### Flow 5: Final Workflow Update
1. User has made all changes (added/activated items)
2. Clicks "Update Workflow" button
3. Confirmation dialog appears listing what will be activated
4. Clicks "OK" to confirm
5. All pending records are activated
6. Success message appears

---

## Styling

Both components use Salesforce Lightning Base Components with custom CSS:

- `manageWorkflow.css` - Styles for transition boxes and diagram
- `manageWorkflowForm.css` - Styles for form presentation

---

## Notes

- All API responses are wrapped in `APIResponse` containing `{ success, message, data }`
- Modals use Lightning web component `lightning-modal` base components
- Comboboxes are populated dynamically from controller data
- All operations include loading spinners and error/success messaging
- Workflow transitions are color-coded: Green for active, Orange for pending

