# 07 — Contextual Action Parameter Inspector Panel

**What to build:** A contextual right-side inspector panel that slides out or populates when an action is selected in either the Action Library or Active Menu Canvas, presenting activation condition rules (files, folders, desktop container), bound target applications, and action-specific configuration parameters.

**Blocked by:** 04 — Action Library Pane & Reactive State Coordinator, 05 — Active Menu Staging Canvas & Drag-and-Drop Reordering

**Status:** resolved

- [x] Inspector displays selected action icon, title, description, and internal action identifier.
- [x] Shows target availability scopes: Single File, Multiple Files, Directory/Folder, or Blank Desktop Area with interactive toggles.
- [x] For Terminal/IDE and external launcher actions, provides application selector / path picker.
- [x] For New File / Template actions, provides filename prefix and default template configuration fields.
- [x] Modifications made inside the inspector update the action definition and trigger immediate synchronization.
- [x] Inspector can be collapsed or expanded cleanly without breaking dual-pane layout proportions.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Contextual Inspector Panel & Parameter Binding.
