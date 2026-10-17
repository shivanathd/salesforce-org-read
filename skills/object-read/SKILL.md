---
name: object-read
description: Read the automation on one Salesforce object without changing it - Apex triggers, record-triggered flows and their order, Workflow Rules, active validation rules and Process Builder - and say what fires on save. Use when someone asks what runs on Account, Opportunity or another object, or why saving a record is slow or fails.
---

# Object read

Read-only, same rules as the `org-read` skill (CLI path, never `sf org display`).

Run, with the object's API name (letters, digits and underscores only, for example `Account` or `Invoice__c`):
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object <ObjectApiName>`

It prints six results, in order:
1. The object (EntityDefinition). If it has no row, or the script says "object not found", stop and say so.
2. Apex triggers on the object (ApexTrigger), including managed-package triggers (NamespacePrefix set), with API version and status.
3. Flows triggered by the object (FlowDefinitionView), with TriggerType, TriggerOrder, IsActive and NamespacePrefix. Custom objects are matched by their Id, so this works for them too.
4. Workflow Rules on the object (WorkflowRule). These show the rule exists, not whether it is active.
5. The count of active validation rules (ValidationRule).
6. Active Process Builder processes in the whole org. Salesforce does not store a process's object in a field this read can filter on, so say "may run on this object" and list them only if there are any.

Check each JSON `status`; a failed query is Unassessed with its error name.

Write a short list in Salesforce's order of execution (Apex Developer Guide, "Triggers and Order of Execution"), using only the steps that have something on this object:
1. System validation
2. Before-save record-triggered flows
3. Before triggers
4. Custom validation rules
5. Duplicate rules
6. Save (not yet committed)
7. After triggers
8. Assignment and auto-response rules
9. Workflow Rules. Their field updates run before and after update triggers once more.
10. Escalation rules
11. Process Builder processes
12. After-save record-triggered flows
13. Roll-up summaries to parent records, then commit

For each item give Evidence (count), Confidence and an outcome from the `verdict` skill.
- Flag active record-triggered flows of the same TriggerType with no TriggerOrder, or two with the same TriggerOrder. Gaps such as 10, 20, 30 are normal.
- More than one trigger for the same event has no guaranteed order: say so if there are two or more active triggers.
- A trigger and a flow on the same object is a review item, not proof of duplication.
