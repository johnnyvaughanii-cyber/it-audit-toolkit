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