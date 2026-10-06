# =============================================================
#  WP-LA-09-01 | Shared Account Governance Review
# -------------------------------------------------------------
#  Control objective : Shared and generic accounts are governed.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Authentication
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population test of accounts with
#                      AccountType Shared. Enabled accounts
#                      tested for credential age against a
#                      365-day threshold and for MFA enrollment.
#                      Named owner and documented purpose are
#                      not in the directory extract and are not
#                      tested here. No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================

$auditPath = "C:\Projects\it-audit-toolkit"

$ad  = Import-Csv "$auditPath\data\ad_user_accounts.csv"

$shared = $ad | Where-Object { $_.AccountType -eq "Shared" }
$shared.Count

$shared |
    Select-Object SamAccountName, DisplayName, Enabled, LastLogonDate, PasswordLastSet, PrivilegedGroup, MFAEnrolled -First 4 |
    Format-Table

$sharedEnabled = $shared | Where-Object { $_.Enabled -eq "TRUE" }
$sharedEnabled.Count

$asOfDate  = [datetime]"08/29/2026"
$maxPwdAge = 365
$cutoff    = $asOfDate.AddDays(-$maxPwdAge)

$sharedStale = $sharedEnabled | Where-Object { [datetime]$_.PasswordLastSet -lt $cutoff }
$sharedStale.Count

$sharedDisabled = $shared.Count - $sharedEnabled.Count
$sharedNoMFA    = $sharedEnabled | Where-Object { $_.MFAEnrolled -eq "FALSE" }

"Shared $($shared.Count) = Enabled $($sharedEnabled.Count) + Disabled $sharedDisabled"
"Enabled $($sharedEnabled.Count): Stale credential $($sharedStale.Count), No MFA $($sharedNoMFA.Count)"

$shared |
    Export-Csv "$auditPath\workpapers\WP-LA-09-01_Shared_Accounts.csv" -NoTypeInformation

$sharedEnabled |
    Export-Csv "$auditPath\workpapers\WP-LA-09-02_Shared_Enabled_Exceptions.csv" -NoTypeInformation