#!/usr/bin/env bash
# Usage: bash org-read-cli.sh <target-org-alias> <check> [object]
# Runs read-only sf queries for one check and prints sf's JSON. Each query runs even if another fails
# (for example when the user lacks "View Setup and Configuration"), and a failure prints sf's error JSON.
# The checks object, object-code and field-descriptions take a third argument: an object API name
# (or, for object-code, the object's EntityDefinition DurableId). It must match ^[A-Za-z0-9_]+$.
set -uo pipefail
if ! command -v sf >/dev/null 2>&1; then
  echo "sf not found: install the Salesforce CLI (https://developer.salesforce.com/tools/salesforcecli), then run sf org login web" >&2
  exit 3
fi
usage="usage: bash org-read-cli.sh <org-alias> <org|licences|flows|workflow|triggers|tests|old-code|security|admins|permissions|packages|integrations|async|limits|renewal|recent-changes|flow-descriptions|class-coverage|api-45|fields|inventory> | <org-alias> <object|object-code|field-descriptions> <ObjectApiName>"
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "$usage" >&2
  exit 2
fi
org="$1"; check="$2"; obj="${3:-}"
case "$check" in
  object|object-code|field-descriptions)
    # The name goes into SOQL, so only letters, digits and underscores are allowed.
    if ! [[ "$obj" =~ ^[A-Za-z0-9_]+$ ]]; then
      echo "$check needs an object API name made of letters, digits and underscores, for example Account or Invoice__c" >&2
      exit 2
    fi ;;
  *)
    if [ -n "$obj" ]; then echo "$usage" >&2; exit 2; fi ;;
esac
q()  { sf data query --target-org "$org" --json --query "$1" || true; }
qt() { sf data query --target-org "$org" --json --use-tooling-api --query "$1" || true; }
case "$check" in
  org)
    # Which org this login points at. Compare the Id with the hosted path before combining results.
    q "SELECT Id, Name, OrganizationType, IsSandbox FROM Organization" ;;
  licences)
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND (LastLoginDate < LAST_N_DAYS:90 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name"
    q "SELECT Name, TotalLicenses, UsedLicenses, Status FROM UserLicense"
    q "SELECT MasterLabel, TotalLicenses, UsedLicenses FROM PermissionSetLicense" ;;
  flows)
    # At most 200 rows, so a large org doesn't flood the context (FlowDefinitionView has no COUNT).
    q "SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel, TriggerOrder, IsActive, IsOutOfDate, ApiVersion, LastModifiedDate FROM FlowDefinitionView ORDER BY LastModifiedDate DESC LIMIT 200" ;;
  workflow)
    # Tooling WorkflowRule has no Active field; it only shows which rules exist on which object.
    qt "SELECT Id, Name, TableEnumOrId FROM WorkflowRule ORDER BY TableEnumOrId LIMIT 200" ;;
  triggers)
    qt "SELECT Name, TableEnumOrId, ApiVersion, Status FROM ApexTrigger WHERE NamespacePrefix = null ORDER BY TableEnumOrId LIMIT 200"
    # Record-triggered flows with the triggering object's Id and API name, to match TableEnumOrId above.
    q "SELECT ApiName, TriggerType, TriggerOrder, TriggerObjectOrEventId, TriggerObjectOrEvent.QualifiedApiName FROM FlowDefinitionView WHERE TriggerType IN ('RecordBeforeSave', 'RecordAfterSave', 'RecordBeforeDelete') LIMIT 200" ;;
  tests)
    q  "SELECT Id, AsyncApexJobId, Status, StartTime, MethodsCompleted, MethodsFailed FROM ApexTestRunResult ORDER BY StartTime DESC LIMIT 5"
    qt "SELECT PercentCovered FROM ApexOrgWideCoverage" ;;
  old-code)
    # Legacy metadata versions: Apex saved on API 30 or lower. Salesforce's retirement of API versions
    # 21 to 30 (Summer '25) affects API calls made on those versions, not Apex saved at them, so this
    # is tech debt to review. Integrations still calling old versions are not visible here.
    qt "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200"
    qt "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200" ;;
  security)
    qt "SELECT Score FROM SecurityHealthCheck"
    qt "SELECT RiskType, Setting, SettingGroup, OrgValue, StandardValue FROM SecurityHealthCheckRisks WHERE RiskType = 'HIGH_RISK'" ;;
  admins)
    # Active users with Modify All Data. The first query returns one row per distinct user, through a profile
    # (profile-owned permission sets are permission sets too) or a permission set. The other two are the breakdown.
    q "SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true AND Assignee.IsActive = true GROUP BY AssigneeId LIMIT 2000"
    q "SELECT COUNT(Id) FROM User WHERE IsActive = true AND Profile.PermissionsModifyAllData = true"
    q "SELECT PermissionSet.Name, COUNT(AssigneeId) FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true AND PermissionSet.IsOwnedByProfile = false AND Assignee.IsActive = true GROUP BY PermissionSet.Name" ;;
  permissions)
    # Custom profiles, then permission sets (including managed-package ones).
    q "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = true AND IsCustom = true"
    q "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = false" ;;
  packages)
    qt "SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix, SubscriberPackageVersion.Name FROM InstalledSubscriberPackage LIMIT 200" ;;
  integrations)
    # Named Credentials and Connected Apps that exist. A listed app does not prove it holds tokens.
    q "SELECT DeveloperName, PrincipalType FROM NamedCredential LIMIT 200"
    q "SELECT Name FROM ConnectedApplication LIMIT 200" ;;
  async)
    # Background Apex jobs from the last 7 days, by type and status.
    q "SELECT JobType, Status, COUNT(Id), SUM(NumberOfErrors) FROM AsyncApexJob WHERE CreatedDate = LAST_N_DAYS:7 GROUP BY JobType, Status" ;;
  limits)
    sf org list limits --target-org "$org" --json || true ;;
  renewal)
    # Active users with no login in 60 days, by licence (the 90-day count is in licences).
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND (LastLoginDate < LAST_N_DAYS:60 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name" ;;
  recent-changes)
    # Apex and flows changed in the last 90 days, counted by who changed them.
    q "SELECT LastModifiedBy.Name, COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90 GROUP BY LastModifiedBy.Name"
    q "SELECT LastModifiedBy.Name, COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90 GROUP BY LastModifiedBy.Name"
    q "SELECT ApiName, LastModifiedBy, LastModifiedDate FROM FlowDefinitionView WHERE LastModifiedDate = LAST_N_DAYS:90 ORDER BY LastModifiedDate DESC LIMIT 200" ;;
  flow-descriptions)
    q "SELECT ApiName, ProcessType, IsActive FROM FlowDefinitionView WHERE Description = null ORDER BY ApiName LIMIT 200" ;;
  class-coverage)
    # Per class or trigger coverage from the last test runs, plus Ids and names to read it by.
    qt "SELECT ApexClassOrTriggerId, NumLinesCovered, NumLinesUncovered FROM ApexCodeCoverageAggregate LIMIT 500"
    q  "SELECT Id, Name FROM ApexClass WHERE NamespacePrefix = null ORDER BY Name LIMIT 500"
    q  "SELECT Id, Name FROM ApexTrigger WHERE NamespacePrefix = null ORDER BY Name LIMIT 500" ;;
  api-45)
    # Apex below API 45 keeps JDK locale formats even when ICU locale formats are on.
    qt "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion < 45 ORDER BY ApiVersion LIMIT 200"
    qt "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion < 45 ORDER BY ApiVersion LIMIT 200" ;;
  fields)
    # Custom fields per object. Custom objects show as Ids; the second query maps them to names.
    qt "SELECT TableEnumOrId, COUNT(Id) FROM CustomField WHERE NamespacePrefix = null GROUP BY TableEnumOrId LIMIT 200"
    qt "SELECT Id, DeveloperName FROM CustomObject WHERE NamespacePrefix = null ORDER BY DeveloperName LIMIT 500" ;;
  inventory)
    q  "SELECT COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null"
    q  "SELECT COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null"
    qt "SELECT COUNT(Id) FROM CustomObject WHERE NamespacePrefix = null" ;;
  object)
    # One object: its EntityDefinition DurableId (EntityDefinition ignores LIMIT; the name filter returns one row),
    # validation rules, and flows it triggers. Run object-code with the DurableId for triggers and Workflow Rules.
    qt "SELECT DurableId, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = '$obj'"
    qt "SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = '$obj' LIMIT 200"
    q  "SELECT ApiName, ProcessType, TriggerType, RecordTriggerType, TriggerOrder, IsActive FROM FlowDefinitionView WHERE TriggerObjectOrEvent.QualifiedApiName = '$obj' LIMIT 200" ;;
  object-code)
    # TableEnumOrId holds the name for standard objects and the Id for custom ones: pass the DurableId from object.
    qt "SELECT Name, ApiVersion, Status FROM ApexTrigger WHERE TableEnumOrId = '$obj' LIMIT 200"
    qt "SELECT Id, Name FROM WorkflowRule WHERE TableEnumOrId = '$obj' LIMIT 200" ;;
  field-descriptions)
    # FieldDefinition ignores LIMIT and needs an object filter; one object per call.
    qt "SELECT QualifiedApiName, Description FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = '$obj'" ;;
  *) echo "unknown check: $check" >&2; exit 2 ;;
esac
