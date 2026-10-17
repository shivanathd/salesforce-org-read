---
name: object-read
description: Read the automation on one Salesforce object without changing it - Apex triggers, record-triggered flows and their order, Workflow Rules and active validation rules - and say what fires on save. Use when someone asks what runs on Account, Opportunity or another object, or why saving a record is slow or fails.
---

# Object read

Read-only, same rules as the `org-read` skill (CLI path, never `sf org display`).

Run, with the object's API name (letters, digits and underscores only, for example `Account` or `Invoice__c`):
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/org-read-cli.sh" <alias> object <ObjectApiName>`

It prints four results, in order:
1. Unmanaged Apex triggers on the object (ApexTrigger), with API version and status.
2. Flows triggered by the object (FlowDefinitionView), with TriggerType, TriggerOrder, IsActive and NamespacePrefix.
3. Workflow Rules on the object (WorkflowRule). These show the rule exists, not whether it is active.
4. The count of active validation rules (ValidationRule).

Check each JSON `status`; a failed query is Unassessed with its error name. For a custom object, the flow and Workflow Rule lists may match on the object's Id rather than its name: if both are empty, say "none found by name" rather than "none".

Write a short list, in the order Salesforce runs them on save: before-save flows, validation rules, triggers, after-save flows, Workflow Rules. For each item give Evidence (count), Confidence and an outcome from the `verdict` skill.
- Flag active record-triggered flows of the same TriggerType with no TriggerOrder, or two with the same TriggerOrder. Gaps such as 10, 20, 30 are normal.
- A trigger and a flow on the same object is a review item, not proof of duplication.
