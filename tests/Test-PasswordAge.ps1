# =============================================================
#  WP-LA-09 | Credential Rotation Review
# -------------------------------------------------------------
#  Control objective : Credentials are rotated in accordance
#                      with policy.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Authentication
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population test of enabled accounts
#                      against a 365-day credential age
#                      threshold. No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================
$auditPath = "C:\Projects\it-audit-toolkit"

$ad = Import-Csv "$auditPath\data\ad_user_accounts.csv"

$ad = $ad | Select-Object *, @{
    Name       = "PwdSetDate"
    Expression = { [datetime]$_.PasswordLastSet }
}

$asOfDate  = [datetime]"08/29/2026"
$maxPwdAge = 365
$cutoff    = $asOfDate.AddDays(-$maxPwdAge)
$cutoffset

$stalePwd = $ad | Where-Object {
    $_.Enabled -eq "TRUE" -and $_.PwdSetDate -lt $cutoff
}

$stalePwd.Count

$stalePwd = $stalePwd | Select-Object *, @{
    Name       = "DaysSincePwdSet"
    Expression = { ($asOfDate - $_.PwdSetDate).Days }
}

$stalePwd |
    Sort-Object DaysSincePwdSet -Descending |
    Select-Object SamAccountName, DisplayName, Department, DaysSincePwdSet, PrivilegedGroup -First 15 |
    Format-Table

$stalePwdPriv = $stalePwd | Where-Object { $_.PrivilegedGroup -ne "" }

$stalePwdPriv.Count

$stalePwd |
    Sort-Object DaysSincePwdSet -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-09_Stale_Credentials.csv" -NoTypeInformation

$stalePwdPriv |
    Sort-Object DaysSincePwdSet -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-10_Stale_Credentials_Privileged.csv" -NoTypeInformation