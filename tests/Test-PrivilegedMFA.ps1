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
