#!/usr/bin/env bash
# Usage: bash org-read-cli.sh <target-org-alias> <check> [object]
# Runs read-only sf queries for one check and prints sf's JSON, one document per query.
# Each query runs even if another fails (for example when the user lacks "View Setup and Configuration"),
# and a failure prints sf's error JSON. Exit code: 0 if every query worked, 1 if any query failed,
# 2 for a usage error or when the sf CLI is not installed.
set -uo pipefail
checks="org|licences|renewal|flows|workflow|triggers|tests|legacy-versions|security|limits|admin-sprawl|permission-debt|packages|integrations|async-failures|handover|fields|inventory|object <ObjectApiName>"
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: bash org-read-cli.sh <org-alias> <$checks>" >&2
  exit 2
fi
if ! command -v sf >/dev/null 2>&1; then
  echo "The Salesforce CLI (sf) is not installed or not on PATH. Install it, then run: sf org login web --alias <alias>" >&2
  exit 2
fi
org="$1"; check="$2"; obj="${3:-}"
failed=0
q()  { sf data query --target-org "$org" --json --query "$1" || failed=1; }
qt() { sf data query --target-org "$org" --json --use-tooling-api --query "$1" || failed=1; }
# Active users who count toward licences: not frozen, not on an integration licence.
seat="IsActive = true AND (NOT Profile.UserLicense.Name LIKE '%Integration%') AND Id NOT IN (SELECT UserId FROM UserLogin WHERE IsFrozen = true)"
# Free licences left out of the renewal cut-sheet.
free="('Chatter Free','Chatter External','Guest User License','Guest','Identity')"
case "$check" in
  org)
    q "SELECT Id, Name, IsSandbox, OrganizationType FROM Organization" ;;
  licences)
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE $seat AND (LastLoginDate < LAST_N_DAYS:90 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name"
    q "SELECT Name, TotalLicenses, UsedLicenses, Status FROM UserLicense"
    q "SELECT MasterLabel, TotalLicenses, UsedLicenses FROM PermissionSetLicense" ;;
  renewal)
    # Paid licences only (no free or integration licences). The 90-day count comes from the licences check.
    q "SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE TotalLicenses > 0 AND Name NOT IN $free AND (NOT Name LIKE '%Integration%')"
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE $seat AND Profile.UserLicense.Name NOT IN $free AND (LastLoginDate < LAST_N_DAYS:60 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name"
    # Frozen users still hold a licence.
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND Profile.UserLicense.Name NOT IN $free AND (NOT Profile.UserLicense.Name LIKE '%Integration%') AND Id IN (SELECT UserId FROM UserLogin WHERE IsFrozen = true) GROUP BY Profile.UserLicense.Name" ;;
  flows)
    # Unmanaged flows only, at most 200 rows (FlowDefinitionView has no COUNT). Process Builder processes
    # are the rows with ProcessType Workflow, CustomEvent or InvocableProcess.
    q "SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel, TriggerOrder, IsActive, IsOutOfDate, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE NamespacePrefix = null ORDER BY LastModifiedDate DESC LIMIT 200" ;;
  workflow)
    # Tooling WorkflowRule has no Active field; it only shows which rules exist on which object.
    qt "SELECT Id, Name, TableEnumOrId FROM WorkflowRule ORDER BY TableEnumOrId LIMIT 200" ;;
  triggers)
    qt "SELECT Name, TableEnumOrId, ApiVersion, Status FROM ApexTrigger WHERE NamespacePrefix = null ORDER BY TableEnumOrId LIMIT 200" ;;
  tests)
    q  "SELECT Id, AsyncApexJobId, Status, StartTime, MethodsCompleted, MethodsFailed FROM ApexTestRunResult ORDER BY StartTime DESC LIMIT 5"
    qt "SELECT PercentCovered FROM ApexOrgWideCoverage" ;;
  legacy-versions)
    # Apex saved on old metadata API versions (30 or lower, then 31 to 44). This shows code age only,
    # not which integrations call retired API versions.
    qt "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200"
    qt "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200"
    qt "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion > 30 AND ApiVersion < 45 ORDER BY ApiVersion LIMIT 200"
    qt "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion > 30 AND ApiVersion < 45 ORDER BY ApiVersion LIMIT 200" ;;
  security)
    qt "SELECT Score FROM SecurityHealthCheck"
    qt "SELECT RiskType, Setting, SettingGroup, OrgValue, StandardValue FROM SecurityHealthCheckRisks WHERE RiskType = 'HIGH_RISK'" ;;
  limits)
    sf org list limits --target-org "$org" --json || failed=1 ;;
  admin-sprawl)
    # One row per distinct active user with Modify All Data, through a profile or a permission set
    # (profiles own a permission set too). Frozen users and integration licences left out.
    q "SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true AND Assignee.IsActive = true AND (NOT Assignee.Profile.UserLicense.Name LIKE '%Integration%') AND AssigneeId NOT IN (SELECT UserId FROM UserLogin WHERE IsFrozen = true) GROUP BY AssigneeId LIMIT 2000" ;;
  permission-debt)
    q "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = true AND IsCustom = true"
    # Custom, unmanaged permission sets (not owned by a profile or a permission set group).
    q "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = false AND IsCustom = true AND NamespacePrefix = null AND Type = 'Regular'" ;;
  packages)
    qt "SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix, SubscriberPackageVersion.Name FROM InstalledSubscriberPackage" ;;
  integrations)
    q "SELECT DeveloperName, PrincipalType, Endpoint FROM NamedCredential"
    q "SELECT Name FROM ConnectedApplication" ;;
  async-failures)
    q "SELECT JobType, Status, COUNT(Id) n, SUM(NumberOfErrors) errs FROM AsyncApexJob WHERE CreatedDate = LAST_N_DAYS:7 GROUP BY JobType, Status" ;;
  handover)
    # What changed in the last 90 days (counts only), flows with no description, per-class coverage.
    qt "SELECT COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90"
    qt "SELECT COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90"
    q  "SELECT ApiName FROM FlowDefinitionView WHERE NamespacePrefix = null AND LastModifiedDate = LAST_N_DAYS:90 LIMIT 200"
    q  "SELECT ApiName FROM FlowDefinitionView WHERE NamespacePrefix = null AND Description = null LIMIT 200"
    qt "SELECT ApexClassOrTrigger.Name, NumLinesCovered, NumLinesUncovered FROM ApexCodeCoverageAggregate LIMIT 200" ;;
  fields)
    # Unmanaged custom fields; the skill counts per object and fields with no description.
    qt "SELECT EntityDefinition.QualifiedApiName, DeveloperName, Description FROM CustomField WHERE NamespacePrefix = null LIMIT 2000" ;;
  inventory)
    qt "SELECT COUNT(Id) FROM CustomObject WHERE NamespacePrefix = null"
    qt "SELECT COUNT(Id) FROM CustomField WHERE NamespacePrefix = null"
    # Active unmanaged flows, without Process Builder, as in the flows check.
    q  "SELECT ApiName FROM FlowDefinitionView WHERE NamespacePrefix = null AND IsActive = true AND ProcessType NOT IN ('Workflow','CustomEvent','InvocableProcess') LIMIT 2000"
    qt "SELECT COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null"
    qt "SELECT COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null"
    q  "SELECT COUNT(Id) FROM NamedCredential"
    q  "SELECT COUNT(Id) FROM ConnectedApplication" ;;
  object)
    # The object name goes into SOQL, so only letters, digits and underscores are accepted.
    if ! [[ "$obj" =~ ^[A-Za-z0-9_]+$ ]]; then
      echo "object check needs an object API name (letters, digits, underscores), e.g. Account" >&2
      exit 2
    fi
    # Custom objects: flows store the object's Id (DurableId), so look it up first.
    # Standard objects: DurableId is the API name.
    qt "SELECT DurableId, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = '$obj'"
    durable=$(sf data query --target-org "$org" --use-tooling-api --result-format csv --query "SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = '$obj'" 2>/dev/null | sed -n 2p | tr -d '\r"')
    if ! [[ "$durable" =~ ^[A-Za-z0-9_]+$ ]]; then
      echo "object not found: $obj" >&2
      exit 1
    fi
    # Managed-package triggers included: they fire on save too (see NamespacePrefix).
    qt "SELECT Name, NamespacePrefix, ApiVersion, Status FROM ApexTrigger WHERE EntityDefinition.QualifiedApiName = '$obj' LIMIT 200"
    q  "SELECT ApiName, Label, ProcessType, TriggerType, TriggerOrder, IsActive, NamespacePrefix FROM FlowDefinitionView WHERE TriggerObjectOrEventId IN ('$obj','$durable') LIMIT 200"
    qt "SELECT Id, Name FROM WorkflowRule WHERE TableEnumOrId IN ('$obj','$durable') LIMIT 200"
    qt "SELECT COUNT(Id) FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = '$obj' AND Active = true"
    # Process Builder does not record its object in a filterable field, so list active ones org-wide.
    q  "SELECT ApiName, Label, ProcessType, NamespacePrefix FROM FlowDefinitionView WHERE IsActive = true AND ProcessType IN ('Workflow','CustomEvent','InvocableProcess') LIMIT 200" ;;
  *) echo "unknown check: $check" >&2; exit 2 ;;
esac
exit "$failed"
