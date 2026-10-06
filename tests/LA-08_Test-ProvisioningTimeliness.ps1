# =============================================================
#  WP-LA-08-01 | Provisioning Timeliness Review
# -------------------------------------------------------------
#  Control objective : Access is provisioned timely upon hire.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Information Security
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population test. Active HR records
#                      compared to the directory extract for
#                      personnel with no account. Each directory
#                      account matched to its HR record by
#                      EmployeeID; account creation date compared
#                      to hire date against a 5-day threshold
#                      ($maxProvisionDays). Accounts with no HR
#                      record are untestable here (see LA-02).
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

$active = $pop | Where-Object { $_.EmploymentStatus -eq "Active" }
$active.Count

$adIDs = $ad.EmployeeID
$adIDs.Count

$noAccount = $active | Where-Object { $_.EmployeeID -notin $adIDs }
$noAccount.Count

$noAccount |
    Select-Object EmployeeID, LastName, FirstName, Department, JobTitle, HireDate |
    Format-Table

$hrLookup = @{}
foreach ($emp in $pop) {
    $hrLookup[$emp.EmployeeID] = $emp
}
$hrLookup.Count

$matched = $ad | Where-Object { $hrLookup.ContainsKey($_.EmployeeID) }
$matched.Count

$matched = $matched | Select-Object *, @{
    Name       = "HireDate"
    Expression = { [datetime]$hrLookup[$_.EmployeeID].HireDate }
}

$matched = $matched | Select-Object *, @{
    Name       = "DaysToProvision"
    Expression = { ([datetime]$_.WhenCreated - $_.HireDate).Days }
}

$matched | Select-Object SamAccountName, HireDate, WhenCreated, DaysToProvision -First 5 | Format-Table

$matched | Measure-Object DaysToProvision -Minimum -Maximum

$maxProvisionDays = 5

$late  = $matched | Where-Object { $_.DaysToProvision -gt $maxProvisionDays }
$early = $matched | Where-Object { $_.DaysToProvision -lt 0 }

$late.Count
$early.Count

$untestable   = $ad.Count - $matched.Count
$withinPolicy = $matched.Count - $late.Count - $early.Count

"Population $($ad.Count) = Tested $($matched.Count) + Untestable $untestable"
"Tested $($matched.Count) = Within policy $withinPolicy + Late $($late.Count) + Early $($early.Count)"

$noAccount |
    Export-Csv "$auditPath\workpapers\WP-LA-08-01_Active_No_Account.csv" -NoTypeInformation

$late |
    Sort-Object DaysToProvision -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-08-02_Provisioned_Late.csv" -NoTypeInformation

$early |
    Sort-Object DaysToProvision |
    Export-Csv "$auditPath\workpapers\WP-LA-08-03_Provisioned_Before_Hire.csv" -NoTypeInformation