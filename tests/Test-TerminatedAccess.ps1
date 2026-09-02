# =============================================================
#  WP-LA-01 | Termination-to-Access Reconciliation
# -------------------------------------------------------------
#  Control objective : Logical access is revoked timely upon
#                      separation from the organization.
#
#  Framework ref     : SOX ITGC - Access to Programs and Data
#                      FFIEC IT Handbook - Information Security
#                      COBIT 5 DSS05.04
#
#  Method            : Full-population reconciliation of the HR
#                      termination listing against the directory
#                      account extract. No sampling.
#
#  Data access       : Read-only. This script does not create,
#                      modify, or disable any account.
#
#  Population as of  : 08/29/2026
# =============================================================


# --- Setup -----------------------------------------------------
# Set the folder once. A reviewer repoints the script at their own
# extract by editing this single line, without touching test logic.

$auditPath = "C:\Projects\Audit"

$pop = Import-Csv "$auditPath\hr_roster.csv"
$ad  = Import-Csv "$auditPath\ad_user_accounts.csv"


# --- Population completeness -----------------------------------
# Establish and document the population before any filtering.
# Strata must reconcile to the population total.

$pop.Count
$ad.Count
$pop | Group-Object EmploymentStatus | Select-Object Name, Count


# --- Isolate the terminated population -------------------------

$terms = $pop | Where-Object { $_.EmploymentStatus -eq "Terminated" }
$terms.Count


# --- Extract the lookup list -----------------------------------
# Count is re-checked here. 91 terminated records must yield 91
# identifiers. A mismatch means the population was not carried
# through the transformation intact.

$termIDs = $terms.EmployeeID
$termIDs.Count


# --- The reconciliation ----------------------------------------
# Keep directory accounts where the employee identifier appears
# in the terminated listing AND the account remains enabled.
#
# The second condition is what isolates control failures. Without
# it, every terminated user's account would flag, including those
# properly disabled.

$exceptions = $ad | Where-Object {
    $_.EmployeeID -in $termIDs -and $_.Enabled -eq "TRUE"
}
$exceptions.Count


# --- Review the exceptions -------------------------------------
# LastLogonDate is the field to watch. Activity recorded after the
# termination date elevates the finding from a provisioning gap to
# evidence of post-separation access.

$exceptions |
    Select-Object SamAccountName, DisplayName, EmployeeID, Department, LastLogonDate |
    Format-Table


# --- Stratify exceptions by department -------------------------
# Note: raw counts favor large departments. The defensible
# statement compares exception rate to each department's share of
# total terminations, not the raw count.

$exceptions |
    Group-Object Department |
    Sort-Object Count -Descending |
    Format-Table Name, Count


# --- Assess severity: privileged access ------------------------
# Filters the already-filtered set. Each layer narrows the
# population further, drilling from finding into severity.

$privExceptions = $exceptions | Where-Object { $_.PrivilegedGroup -ne "" }
$privExceptions.Count

$privExceptions |
    Select-Object SamAccountName, DisplayName, Department, PrivilegedGroup, MFAEnrolled |
    Format-Table


# --- Retain evidence -------------------------------------------
# Screen output was trimmed for readability. The exported
# workpaper retains all fields, since a reviewer needs the
# complete record.

$exceptions |
    Export-Csv "$auditPath\workpapers\WP-LA-01_Terminated_Enabled_Accounts.csv" -NoTypeInformation

$privExceptions |
    Export-Csv "$auditPath\workpapers\WP-LA-02_Privileged_Terminated_Accounts.csv" -NoTypeInformation
