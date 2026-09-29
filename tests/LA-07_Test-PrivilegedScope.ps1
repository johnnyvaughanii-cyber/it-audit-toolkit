# =============================================================
#  WP-LA-07-01 | Privileged Access Scope Review
# -------------------------------------------------------------
#  Control objective : Privileged access is limited to those
#                      requiring it.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Information Security
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population test of enabled accounts.
#                      Privileged accounts measured as a
#                      proportion of the enabled population and
#                      stratified by department. Accounts outside
#                      the departments listed in $expectedDepts
#                      isolated for review. No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================
$auditPath = "C:\Projects\it-audit-toolkit"

$ad = Import-Csv "$auditPath\data\ad_user_accounts.csv"

$enabled = $ad | Where-Object { $_.Enabled -eq "TRUE" }
$enabled.Count

$privileged = $ad | Where-Object {
    $_.Enabled -eq "TRUE" -and $_.PrivilegedGroup -ne ""
}
$privileged.Count

$privPct = [math]::Round(($privileged.Count / $enabled.Count) * 100, 1)
$privPct

$privileged |
    Select-Object SamAccountName, DisplayName, Department, AccountType, PrivilegedGroup |
    Format-Table

$privileged | Group-Object Department | Sort-Object Count -Descending | Format-Table Name, Count

$expectedDepts = @("Information Technology")

$outOfScope = $privileged | Where-Object { $_.Department -notin $expectedDepts }
$outOfScope.Count

$outOfScope |
    Sort-Object Department |
    Select-Object SamAccountName, DisplayName, Department, AccountType, PrivilegedGroup |
    Format-Table

$privileged |
    Export-Csv "$auditPath\workpapers\WP-LA-07-01_Privileged_Enabled_Population.csv" -NoTypeInformation

$outOfScope |
    Sort-Object Department |
    Export-Csv "$auditPath\workpapers\WP-LA-07-02_Privileged_Out_Of_Scope.csv" -NoTypeInformation