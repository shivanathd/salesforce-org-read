#!/usr/bin/env bash
# Usage: bash org-read-cli.sh <target-org-alias> <check>
# Runs read-only sf queries for one check and prints sf's JSON. Each query runs even if another fails
# (for example when the user lacks "View Setup and Configuration"), and a failure prints sf's error JSON.
set -uo pipefail
if ! command -v sf >/dev/null 2>&1; then
  echo "sf not found: install the Salesforce CLI (https://developer.salesforce.com/tools/salesforcecli), then run sf org login web" >&2
  exit 3
fi
if [ $# -ne 2 ]; then
  echo "usage: bash org-read-cli.sh <org-alias> <org|licences|flows|workflow|triggers|tests|old-code|security|admins|permissions|limits>" >&2
  exit 2
fi
org="$1"; check="$2"
q()  { sf data query --target-org "$org" --json --query "$1" || true; }
qt() { sf data query --target-org "$org" --json --use-tooling-api --query "$1" || true; }
case "$check" in
  org)
    # Which org this login points at. Compare the Id with the hosted path before combining results.
    q "SELECT Id, Name, OrganizationType, IsSandbox FROM Organization" ;;
  licences)
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND (LastLoginDate < LAST_N_DAYS:90 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name"
    q "SELECT Name, TotalLicenses, UsedLicenses, Status FROM UserLicense" ;;
  flows)
    # At most 200 rows, so a large org doesn't flood the context (FlowDefinitionView has no COUNT).
    q "SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel, TriggerOrder, IsActive, IsOutOfDate, ApiVersion, LastModifiedDate FROM FlowDefinitionView ORDER BY LastModifiedDate DESC LIMIT 200" ;;
  workflow)
    # Tooling WorkflowRule has no Active field; it only shows which rules exist on which object.
    qt "SELECT Id, Name, TableEnumOrId FROM WorkflowRule ORDER BY TableEnumOrId LIMIT 200" ;;
  triggers)
    qt "SELECT Name, TableEnumOrId, ApiVersion, Status FROM ApexTrigger WHERE NamespacePrefix = null ORDER BY TableEnumOrId LIMIT 200" ;;
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
    # Active users with Modify All Data, through their profile and through permission sets.
    q "SELECT COUNT(Id) FROM User WHERE IsActive = true AND Profile.PermissionsModifyAllData = true"
    q "SELECT PermissionSet.Name, COUNT(AssigneeId) FROM PermissionSetAssignment WHERE PermissionSet.PermissionsModifyAllData = true AND PermissionSet.IsOwnedByProfile = false AND Assignee.IsActive = true GROUP BY PermissionSet.Name" ;;
  permissions)
    # Custom profiles, then permission sets (including managed-package ones).
    q "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = true AND IsCustom = true"
    q "SELECT COUNT(Id) FROM PermissionSet WHERE IsOwnedByProfile = false" ;;
  limits)
    sf org list limits --target-org "$org" --json || true ;;
  *) echo "unknown check: $check" >&2; exit 2 ;;
esac
