---
name: lwc-error-handling-guide
description: >
  When an LWC needs to surface a failure (Apex error, validation failure, missing
  precondition) to the user, dispatch a `ShowToastEvent` with `variant: 'error'`
  — do NOT store the message in a tracked `errorMessage` / `_errorMessage` field
  and render it inline. Toasts are the project's standard error channel; an
  inline error region competes with toasts, leaks failure UI into the page
  layout, and forces every error path to also manage a "dismiss" handler.

---

# LWC Error Handling

Every failure surfaced from an LWC goes through `ShowToastEvent`. No tracked
`errorMessage` fields, no inline error banners with a Dismiss button, no
component-local error state to clear on the next render. The toast is the
single, consistent error channel across the app.

---

## The pattern

```js
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

_toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
}
```

Call `this._toast('Error', message, 'error')` from:
- `.catch(err => ...)` of an imperative Apex call
- The `result.error` / `result.data.success === false` branches of a `@wire` callback
- Synchronous validation failures before any Apex is dispatched

---

## Worked example (from this session — `chooseProject`)

The first draft of `chooseProject.js` held an `@track _errorMessage` and an
inline `.splash__error` banner with a Dismiss button. The corrected version
removes that state entirely and routes every failure through a toast.

**Before** — tracked field + inline banner + dismiss handler:

```js
@track _errorMessage = null;

@wire(loadAllProjects)
wiredLoadAllProjects(result) {
    if (result.data) {
        if (result.data.success) {
            this._projects     = result.data.data || [];
            this._errorMessage = null;
        } else {
            this._errorMessage = result.data.message || 'Failed to load projects';
        }
    } else if (result.error) {
        this._errorMessage = result.error.body?.message || 'Error loading projects';
    }
}

handleCreate() {
    const name = (this._newProjectName || '').trim();
    if (!name) {
        this._errorMessage = 'Project name is required';
        return;
    }
    this._errorMessage = null;
    createProject({ name })
        .then(...)
        .catch(err => {
            this._errorMessage = err.body?.message || err.message || 'Error creating project';
        });
}

handleDismissError() { this._errorMessage = null; }
```

```html
<template if:true={errorMessage}>
    <div class="splash__error" role="alert">
        <span>{errorMessage}</span>
        <button onclick={handleDismissError}>Dismiss</button>
    </div>
</template>
```

**After** — toast only, no error state on the component:

```js
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

@wire(loadAllProjects)
wiredLoadAllProjects(result) {
    if (result.data) {
        if (result.data.success) {
            this._projects = result.data.data || [];
        } else {
            this._toast('Error', result.data.message || 'Failed to load projects', 'error');
        }
    } else if (result.error) {
        this._toast('Error', result.error.body?.message || 'Error loading projects', 'error');
    }
}

handleCreate() {
    const name = (this._newProjectName || '').trim();
    if (!name) {
        this._toast('Error', 'Project name is required', 'error');
        return;
    }
    createProject({ name })
        .then(...)
        .catch(err => {
            this._toast('Error', err.body?.message || err.message || 'Error creating project', 'error');
        });
}

_toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
}
```

The `_errorMessage` field, the `errorMessage` getter, the dismiss handler,
and the entire `.splash__error` markup block are deleted — the toast carries
the message and dismisses itself.

---

## Anti-patterns to refuse

| Anti-pattern | Fix |
|---|---|
| Adding a new `@track errorMessage = null` to a new LWC | Dispatch `ShowToastEvent` from the `.catch` / wire-error branch instead |
| Inline `<div class="error-box">{errorMessage}</div>` + Dismiss button on a NEW component | Remove the banner; rely on the toast |
| Setting `errorMessage` from one handler and `_errorMessage` from another in the same file | Pick one channel (toast) — never split error state across two fields |
| Surfacing the failure ONLY by logging to the console | The user must see it; dispatch a toast |
