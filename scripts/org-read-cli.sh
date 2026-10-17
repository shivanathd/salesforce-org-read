#!/usr/bin/env bash
# Usage: bash org-read-cli.sh <target-org-alias> <check>
# Runs read-only sf queries for one check and prints sf's JSON. Each query runs even if another fails
# (for example when the user lacks "View Setup and Configuration"), and a failure prints sf's error JSON.
set -uo pipefail
if [ $# -ne 2 ]; then
  echo "usage: bash org-read-cli.sh <org-alias> <licences|flows|workflow|triggers|tests|old-code|security|limits>" >&2
  exit 2
fi
org="$1"; check="$2"
q()  { sf data query --target-org "$org" --json --query "$1" || true; }
qt() { sf data query --target-org "$org" --json --use-tooling-api --query "$1" || true; }
case "$check" in
  licences)
    q "SELECT Profile.UserLicense.Name, COUNT(Id) FROM User WHERE IsActive = true AND (LastLoginDate < LAST_N_DAYS:90 OR LastLoginDate = null) GROUP BY Profile.UserLicense.Name"
    q "SELECT Name, TotalLicenses, UsedLicenses, Status FROM UserLicense" ;;
  flows)
    # Counts first, then at most 200 rows, so a large org doesn't flood the context.
    q "SELECT ProcessType, IsActive, COUNT(Id) FROM FlowDefinitionView GROUP BY ProcessType, IsActive"
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
    # Salesforce retired API versions 21 to 30 in Summer '25; code saved on them can stop working.
    qt "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200"
    qt "SELECT Name, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null AND ApiVersion <= 30 ORDER BY ApiVersion LIMIT 200" ;;
  security)
    qt "SELECT Score FROM SecurityHealthCheck"
    qt "SELECT RiskType, Setting, SettingGroup, OrgValue, StandardValue FROM SecurityHealthCheckRisks WHERE RiskType = 'HIGH_RISK'" ;;
  limits)
    sf org list limits --target-org "$org" --json || true ;;
  *) echo "unknown check: $check" >&2; exit 2 ;;
esac
