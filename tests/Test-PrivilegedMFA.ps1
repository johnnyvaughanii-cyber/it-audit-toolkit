# =============================================================
#  WP-LA-07 | Privileged Access MFA Enrollment
# -------------------------------------------------------------
#  Control objective : Privileged access requires multi-factor
#                      authentication.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Authentication
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population test of the directory
#                      account extract. Privileged population
#                      defined as accounts carrying a value in
#                      PrivilegedGroup; accounts holding
#                      privilege granted outside group
#                      membership are not captured. Each tested
#                      for MFA enrollment. No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================
$auditPath = "C:\Projects\it-audit-toolkit"

$ad = Import-Csv "$auditPath\data\ad_user_accounts.csv"

$privileged = $ad | Where-Object { $_.PrivilegedGroup -ne "" }
$privileged.Count

$noMFA = $privileged | Where-Object { $_.MFAEnrolled -eq "FALSE" }
$noMFA.Count

$noMFA |
    Select-Object SamAccountName, DisplayName, Department, AccountType, PrivilegedGroup |
    Format-Table

$noMFA | Group-Object AccountType | Sort-Object Count -Descending | Format-Table Name, Count

$privileged |
    Export-Csv "$auditPath\workpapers\WP-LA-07_Privileged_Population.csv" -NoTypeInformation

$noMFA |
    Export-Csv "$auditPath\workpapers\WP-LA-08_Privileged_No_MFA.csv" -NoTypeInformation