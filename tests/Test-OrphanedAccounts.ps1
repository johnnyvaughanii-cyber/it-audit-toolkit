# =============================================================
#  WP-LA-03 | Account Attribution Review
# -------------------------------------------------------------
#  Control objective : Directory accounts are attributable to an
#                      authorized individual.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Information Security
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population comparison of the directory
#                      account extract against the HR roster.
#                      Unmatched accounts classified as
#                      non-attributable (blank identifier) or
#                      orphaned (populated identifier, no HR
#                      record). No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================
$auditPath = "C:\Projects\it-audit-toolkit"

$pop = Import-Csv "$auditPath\data\hr_roster.csv"
$ad  = Import-Csv "$auditPath\data\ad_user_accounts.csv"

$allEmpIDs = $pop.EmployeeID
$allEmpIDs.Count
$orphans = $ad | Where-Object { $_.EmployeeID -notin $allEmpIDs }
$orphans.Count
$blankID = $orphans | Where-Object { $_.EmployeeID -eq "" }
$blankID.Count

$trueOrphans = $orphans | Where-Object { $_.EmployeeID -ne "" }
$trueOrphans.Count
$trueOrphans |
    Select-Object SamAccountName, DisplayName, EmployeeID, Department, PrivilegedGroup, LastLogonDate |
    Format-Table
$blankID |
    Export-Csv "$auditPath\workpapers\WP-LA-03_Non-Attributable_Accounts.csv" -NoTypeInformation

$trueOrphans |
    Export-Csv "$auditPath\workpapers\WP-LA-04_Orphaned_Accounts.csv" -NoTypeInformation