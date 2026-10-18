#!/bin/bash
# Usage: bash org-read-cli.sh <target-org-alias> <check> [object]
# Runs read-only sf queries for one check. Before each query's JSON it prints a marker line on stdout:
#   ### <check> <n>/<total>: <short label>
# Each query runs even if another fails (for example when the user lacks "View Setup and Configuration"),
# and a failure prints sf's error JSON. Exit 4 when every query in the check failed; exit 3 when sf is missing
# (then stderr says "sf not found"). Exit 2 for bad arguments, checked before looking for sf.
# The checks object, object-code and field-descriptions take a third argument: an object API name,
# for example Account or Invoice__c. It must match ^[A-Za-z0-9_]{1,80}$.
set -uo pipefail
usage="usage: bash org-read-cli.sh <org-alias> <org|whoami|licences|flows|workflow|triggers|tests|old-code|security|admins|permissions|packages|integrations|async|limits|renewal|recent-changes|flow-descriptions|class-coverage|api-45|fields|inventory> | <org-alias> <object|object-code|field-descriptions> <ObjectApiName>"
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "$usage" >&2
  exit 2
fi
org="$1"; check="$2"; obj="${3:-}"
# An alias or username: letters, digits and . _ @ + - only, not starting with -, at most 80 characters.
if ! [[ "$org" =~ ^[A-Za-z0-9_.@+][A-Za-z0-9_.@+-]{0,79}$ ]]; then
  echo "the org alias may hold only letters, digits and . _ @ + - (at most 80 characters, not starting with -)" >&2
  exit 2
fi
case "$check" in
  object|object-code|field-descriptions)
    # The name goes into SOQL, so only letters, digits and underscores are allowed.
    if ! [[ "$obj" =~ ^[A-Za-z0-9_]{1,80}$ ]]; then
      echo "$check needs an object API name made of letters, digits and underscores, for example Account or Invoice__c" >&2
      exit 2
    fi ;;
  *)
    if [ -n "$obj" ]; then echo "$usage" >&2; exit 2; fi ;;
esac

# Each check lists its queries first, so the markers can show <n>/<total>.
# q: standard API query. t: Tooling API query. limits: sf org list limits.
kinds=(); labels=(); queries=()
q()  { kinds+=(q); labels+=("$1"); queries+=("$2"); }
qt() { kinds+=(t); labels+=("$1"); queries+=("$2"); }
# Your own Apex class and trigger counts (used by tests and inventory).
apex_counts() {
  q "your Apex class count" "SELECT COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null"
  q "your Apex trigger count" "SELECT COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null"
}

case "$check" in
  org)
    # Which org this login points at (compare the Id with the hosted path before combining results), and its
    # namespace: when set, the owner's code carries it and NamespacePrefix = null misses it.
    q "org identity and namespace" "SELECT Id, Name, OrganizationType, IsSandbox, NamespacePrefix FROM Organization" ;;
  whoami)
    # The signed-in user's own permissions, as booleans only (no name, no email).
    q "signed-in user permissions" "SELECT PermissionsModifyAllData, PermissionsAuthorApex, PermissionsCustomizeApplication, PermissionsManageUsers, PermissionsViewSetup, PermissionsViewAllUsers FROM UserPermissionAccess" ;;
  licences)
    q "active users with no login in 90 days, by licence" "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND (LastLoginDate < LAST_N_DAYS:90 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name"
    q "user licences" "SELECT Name, TotalLicenses, UsedLicenses, Status FROM UserLicense"
    q "permission set licences" "SELECT MasterLabel, TotalLicenses, UsedLicenses FROM PermissionSetLicense"
    # All active users this login can see, by licence, to compare with UsedLicenses (sharing can hide users).
    q "active users visible to this login, by licence" "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true GROUP BY Profile.UserLicense.Name" ;;
  flows)
    # At most 200 rows each, so a large org doesn't flood the context (FlowDefinitionView has no COUNT).
    q "your own flows" "SELECT ApiName, NamespacePrefix, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel, TriggerOrder, IsActive, IsOutOfDate, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE NamespacePrefix = null ORDER BY LastModifiedDate DESC LIMIT 200"
    q "managed-package flows (left out)" "SELECT ApiName, NamespacePrefix FROM FlowDefinitionView WHERE NamespacePrefix != null LIMIT 200" ;;
  workflow)
    # Tooling WorkflowRule has no Active field; it only shows which rules exist on which object.
    qt "Workflow Rules that exist" "SELECT Id, Name, TableEnumOrId FROM WorkflowRule ORDER BY TableEnumOrId LIMIT 200" ;;
  triggers)
    # Active items only: inactive triggers and flows do not run, so they are not risky automation.
    qt "your active Apex triggers" "SELECT Name, TableEnumOrId, ApiVersion, Status FROM ApexTrigger WHERE NamespacePrefix = null AND Status = 'Active' ORDER BY TableEnumOrId LIMIT 200"
    # Record-triggered flows with the triggering object's Id and API name, to match TableEnumOrId above.
    q "your active record-triggered flows" "SELECT ApiName, NamespacePrefix, TriggerType, TriggerOrder, TriggerObjectOrEventId, TriggerObjectOrEvent.QualifiedApiName FROM FlowDefinitionView WHERE TriggerType IN ('RecordBeforeSave', 'RecordAfterSave', 'RecordBeforeDelete') AND IsActive = true AND NamespacePrefix = null LIMIT 200" ;;
  tests)
    q  "last 5 test runs" "SELECT Id, AsyncApexJobId, Status, StartTime, MethodsCompleted, MethodsFailed FROM ApexTestRunResult ORDER BY StartTime DESC LIMIT 5"
    qt "org-wide coverage" "SELECT PercentCovered FROM ApexOrgWideCoverage"
    # Which of the last 5 runs ran all tests. Kept apart so the tested query above still runs if this one fails.
    q  "last 5 test runs: all tests or some" "SELECT AsyncApexJobId, IsAllTests, ClassesEnqueued, Source FROM ApexTestRunResult ORDER BY StartTime DESC LIMIT 5"
    # Whether the org has Apex of its own: "no Apex to test" needs 0 classes and 0 triggers.
    apex_counts ;;
  old-code)
    # Legacy metadata versions: Apex saved on API 30 or lower. Salesforce's retirement of API versions
    # 21 to 30 (Summer '25) affects API calls made on those versions, not Apex saved at them, so this
    # is tech debt to review. Integrations still calling old versions are not visible here.
    qt "your Apex classes on API 30 or lower" "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200"
    qt "your Apex triggers on API 30 or lower" "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200" ;;
  security)
    qt "Health Check score" "SELECT Score FROM SecurityHealthCheck"
    qt "Health Check high-risk settings" "SELECT RiskType, Setting, SettingGroup, OrgValue, StandardValue FROM SecurityHealthCheckRisks WHERE RiskType = 'HIGH_RISK'" ;;
  admins)
    # Active users with Modify All Data. The first query returns one row per distinct user, through a profile
    # (profile-owned permission sets are permission sets too) or a permission set. The other two are the breakdown.
    q "distinct active users with Modify All Data" "SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true AND Assignee.IsActive = true GROUP BY AssigneeId LIMIT 2000"
    q "breakdown: through profiles" "SELECT COUNT(Id) FROM User WHERE IsActive = true AND Profile.PermissionsModifyAllData = true"
    q "breakdown: through permission sets" "SELECT PermissionSet.Name, COUNT(AssigneeId) FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true AND PermissionSet.IsOwnedByProfile = false AND Assignee.IsActive = true GROUP BY PermissionSet.Name" ;;
  permissions)
    # Custom profiles, then your own custom permission sets (not standard or managed-package ones).
    q "custom profiles" "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = true AND IsCustom = true"
    q "your custom permission sets" "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = false AND IsCustom = true AND NamespacePrefix = null" ;;
  packages)
    qt "installed packages" "SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix, SubscriberPackageVersion.Name FROM InstalledSubscriberPackage LIMIT 200" ;;
  integrations)
    # Named Credentials and Connected Apps that exist. A listed app does not prove it holds tokens.
    q "Named Credentials" "SELECT DeveloperName, PrincipalType FROM NamedCredential LIMIT 200"
    q "Connected Apps" "SELECT Name FROM ConnectedApplication LIMIT 200" ;;
  async)
    # Background Apex jobs from the last 7 days, by type and status.
    q "Apex jobs in the last 7 days, by type and status" "SELECT JobType, Status, COUNT(Id), SUM(NumberOfErrors) FROM AsyncApexJob WHERE CreatedDate = LAST_N_DAYS:7 GROUP BY JobType, Status" ;;
  limits)
    kinds+=(limits); labels+=("org limits"); queries+=("") ;;
  renewal)
    # Active users with no login in 60 days, by licence (the 90-day count is in licences).
    q "active users with no login in 60 days, by licence" "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND (LastLoginDate < LAST_N_DAYS:60 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name" ;;
  recent-changes)
    # Your own Apex and flows changed in the last 90 days, counted by who changed them.
    q "your Apex classes changed in 90 days, by person" "SELECT LastModifiedBy.Name, COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90 GROUP BY LastModifiedBy.Name"
    q "your Apex triggers changed in 90 days, by person" "SELECT LastModifiedBy.Name, COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90 GROUP BY LastModifiedBy.Name"
    q "your flows changed in 90 days" "SELECT ApiName, LastModifiedBy, LastModifiedDate FROM FlowDefinitionView WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90 ORDER BY LastModifiedDate DESC LIMIT 200" ;;
  flow-descriptions)
    q "your flows with no description" "SELECT ApiName, ProcessType, IsActive FROM FlowDefinitionView WHERE NamespacePrefix = null AND Description = null ORDER BY ApiName LIMIT 200" ;;
  class-coverage)
    # Per class or trigger coverage from the last test runs, plus Ids and names to read it by. Most uncovered
    # lines first, so if the 500-row cap is hit the rows read are the least covered ones.
    qt "coverage per class or trigger, most uncovered lines first" "SELECT ApexClassOrTriggerId, NumLinesCovered, NumLinesUncovered FROM ApexCodeCoverageAggregate ORDER BY NumLinesUncovered DESC LIMIT 500"
    q  "your Apex class Ids and names" "SELECT Id, Name FROM ApexClass WHERE NamespacePrefix = null ORDER BY Name LIMIT 500"
    q  "your Apex trigger Ids and names" "SELECT Id, Name FROM ApexTrigger WHERE NamespacePrefix = null ORDER BY Name LIMIT 500" ;;
  api-45)
    # Apex below API 45 keeps JDK locale formats even when ICU locale formats are on.
    qt "your Apex classes below API 45" "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion < 45 ORDER BY ApiVersion LIMIT 200"
    qt "your Apex triggers below API 45" "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion < 45 ORDER BY ApiVersion LIMIT 200" ;;
  fields)
    # Custom fields per object. Custom objects show as 18-character Ids; the second query maps the first 15
    # characters to the API name with its suffix (__c, __mdt, __e, ...) and flags custom settings.
    # EntityDefinition ignores LIMIT and its NamespacePrefix = null filter matches nothing, so it has neither.
    qt "your custom fields per object" "SELECT TableEnumOrId, COUNT(Id) FROM CustomField WHERE NamespacePrefix = null GROUP BY TableEnumOrId LIMIT 500"
    qt "custom object Ids and API names" "SELECT DurableId, QualifiedApiName, IsCustomSetting FROM EntityDefinition WHERE DurableId LIKE '01I%' AND IsCustomizable = true" ;;
  inventory)
    apex_counts
    # Custom objects only (not custom settings, metadata types, platform events, big or external objects).
    # EntityDefinition has no COUNT: count the rows whose name ends in __c with no other __ (others are managed).
    qt "custom objects (count the rows)" "SELECT DurableId, QualifiedApiName FROM EntityDefinition WHERE DurableId LIKE '01I%' AND IsCustomSetting = false AND QualifiedApiName LIKE '%c'" ;;
  object)
    # One object: its EntityDefinition DurableId (EntityDefinition ignores LIMIT; the name filter returns one row),
    # validation rules, and flows it triggers. Run object-code with the same API name for triggers and Workflow Rules.
    qt "object DurableId" "SELECT DurableId, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = '$obj'"
    qt "validation rules" "SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = '$obj' LIMIT 200"
    q  "flows triggered by the object" "SELECT ApiName, NamespacePrefix, ProcessType, TriggerType, RecordTriggerType, TriggerOrder, IsActive FROM FlowDefinitionView WHERE TriggerObjectOrEvent.QualifiedApiName = '$obj' LIMIT 200" ;;
  object-code)
    # TableEnumOrId holds the object API name (Account, Invoice__c) on ApexTrigger and WorkflowRule, for standard
    # and custom objects alike (tested on a scratch org: the custom object's Id finds nothing).
    qt "Apex triggers on the object" "SELECT Name, ApiVersion, Status FROM ApexTrigger WHERE TableEnumOrId = '$obj' LIMIT 200"
    qt "Workflow Rules on the object" "SELECT Id, Name FROM WorkflowRule WHERE TableEnumOrId = '$obj' LIMIT 200" ;;
  field-descriptions)
    # FieldDefinition ignores LIMIT and needs an object filter; one object per call.
    # Every field on the object: a NamespacePrefix filter here matches nothing (tested), so the skills keep
    # only names ending in __c with no other __ (the owner's own custom fields).
    qt "fields and their descriptions" "SELECT QualifiedApiName, Description FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = '$obj'" ;;
  *) echo "unknown check: $check" >&2; exit 2 ;;
esac

if ! command -v sf >/dev/null 2>&1; then
  echo "sf not found: install the Salesforce CLI, then sign it in with sf org login web" >&2
  echo "Salesforce CLI download: https://developer.salesforce.com/tools/salesforcecli" >&2
  exit 3
fi

total=${#queries[@]}
failed=0
for i in "${!queries[@]}"; do
  echo "### $check $((i + 1))/$total: ${labels[$i]}"
  # A failed query prints sf's error JSON and never stops the queries after it.
  if [ "${kinds[$i]}" = limits ]; then
    sf org list limits --target-org "$org" --json || failed=$((failed + 1))
  else
    tooling=(); [ "${kinds[$i]}" = t ] && tooling=(--use-tooling-api)
    sf data query --target-org "$org" --json ${tooling[@]+"${tooling[@]}"} --query "${queries[$i]}" || failed=$((failed + 1))
  fi
done
if [ "$failed" -eq "$total" ]; then
  echo "every query in $check failed: see the error JSON above" >&2
  exit 4
fi
exit 0
