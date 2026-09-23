# =============================================================
#  WP-LA-05 | Dormant Account Review
# -------------------------------------------------------------
#  Control objective : Inactive accounts are identified and
#                      disabled.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Information Security
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population test of enabled accounts
#                      against a 90-day inactivity threshold.
#                      No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================

$auditPath = "C:\Projects\it-audit-toolkit"

$pop = Import-Csv "$auditPath\data\hr_roster.csv"
$ad  = Import-Csv "$auditPath\data\ad_user_accounts.csv"

$ad = $ad | Select-Object *, @{
    Name       = "LogonDate"
    Expression = { [datetime]$_.LastLogonDate } }

$asOfDate    = [datetime]"08/29/2026"
$dormantDays = 90
$cutoff      = $asOfDate.AddDays(-$dormantDays)
$cutoff

$dormant = $ad | Where-Object {
    $_.Enabled -eq "TRUE" -and $_.LogonDate -lt $cutoff
}
$dormant.Count

$dormant = $dormant | Select-Object *, @{
    Name       = "DaysInactive"
    Expression = { ($asOfDate - $_.LogonDate).Days }
}

$dormant |
    Sort-Object DaysInactive -Descending |
    Select-Object SamAccountName, DisplayName, Department, DaysInactive, PrivilegedGroup -First 15 |
    Format-Table

$dormantPriv = $dormant | Where-Object { $_.PrivilegedGroup -ne "" }
$dormantPriv.Count

$dormant |
    Sort-Object DaysInactive -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-05_Dormant_Accounts.csv" -NoTypeInformation

$dormantPriv |
    Sort-Object DaysInactive -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-06_Dormant_Privileged_Accounts.csv" -NoTypeInformation