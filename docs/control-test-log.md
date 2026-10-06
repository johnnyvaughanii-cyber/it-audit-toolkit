# Control Test Development Log

Working record of each control test in `tests/`: the script as run, the
technique notes behind it, and the audit reasoning. Control objectives, test
methods, and framework references are in `control-matrix.md`. PowerShell
syntax is in `PowerShell_Audit_Dictionary.md`.

---

## LA-00 — Population Import and Stratification

**Audit purpose:** Establish population completeness and document composition prior to selection.

```powershell
$auditPath = "C:\Projects\Audit"
$pop = Import-Csv "$auditPath\hr_roster.csv"
$ad  = Import-Csv "$auditPath\ad_user_accounts.csv"

$pop.Count
$ad.Count
$pop | Group-Object EmploymentStatus | Select-Object Name, Count
```

**Result:** 487 HR records, 496 AD accounts. 396 Active + 91 Terminated = 487. Strata reconcile.

**Why set `$auditPath` once:** A reviewer can repoint the script at their own extract by editing one line, without touching the testing logic.

---

## LA-01 — Termination-to-Access Reconciliation

**Control objective:** Logical access is revoked timely upon separation.

```powershell
# --- Isolate terminated population ---
$terms = $pop | Where-Object { $_.EmploymentStatus -eq "Terminated" }
$terms.Count                                    # 91 — ties to stratification

# --- Extract lookup list ---
$termIDs = $terms.EmployeeID
$termIDs.Count                                  # 91 — nothing dropped in extraction

# --- The reconciliation ---
$exceptions = $ad | Where-Object { $_.EmployeeID -in $termIDs -and $_.Enabled -eq "TRUE" }
$exceptions.Count                               # 24

# --- Review the exceptions ---
$exceptions | Select-Object SamAccountName, DisplayName, EmployeeID, Department, LastLogonDate | Format-Table

# --- Stratify exceptions by department ---
$exceptions | Group-Object Department | Sort-Object Count -Descending | Format-Table Name, Count

# --- Assess severity: privileged access ---
$privExceptions = $exceptions | Where-Object { $_.PrivilegedGroup -ne "" }
$privExceptions.Count                           # 5
$privExceptions | Select-Object SamAccountName, DisplayName, Department, PrivilegedGroup, MFAEnrolled | Format-Table

# --- Retain evidence ---
$exceptions     | Export-Csv "$auditPath\workpapers\WP-LA-01-01_Terminated_Enabled_Accounts.csv" -NoTypeInformation
$privExceptions | Export-Csv "$auditPath\workpapers\WP-LA-01-02_Privileged_Terminated_Accounts.csv" -NoTypeInformation
```

**Results:** 24 of 91 terminated users retained enabled accounts (26% failure rate). 5 of those 24 held privileged group membership: Server Operators 2, Backup Operators 2, SQL_DBA_Admins 1. One Backup Operators account had no MFA enrollment.

### Technique notes

- **Reconcile counts at each transformation.** 91 terminated became 91 IDs extracted. Matching counts evidence that the testing population stayed complete through each step.
- **Layered filtering.** `$privExceptions` was built from `$exceptions`, which was built from `$ad`. Each layer narrows the population. This is how you drill from a finding into its severity.
- **`-and` does the real work** in the reconciliation. Without it, every terminated user's account would flag, including properly disabled ones. The second condition is what isolates actual control failures.
- **Trim columns for display, export everything.** The screen view used 5 columns for readability; the exported workpaper retained all 11. A reviewer needs the full record.

### Audit notes

- **Raw counts by department can mislead.** Large departments produce more exceptions by headcount alone. The defensible statement compares exception rate to each department's share of total terminations.
- **IT concentration is meaningful for a different reason** — it is the function that performs deprovisioning, and its personnel are most likely to hold privileged access.
- **Backup Operators is under-weighted by auditors.** The group can read and restore files regardless of the permissions set on them, bypassing file-level access controls by design. Sounds custodial, is not.
- **Post-separation `LastLogonDate`** changes the finding from a provisioning gap to evidence of post-separation access. Different severity, different reporting timeline.
- **Two-tier finding here:** privileged group membership retained post-separation, and an unenrolled privileged account. Different remediation owners, different timelines.

---

## LA-02 — Orphaned Accounts

**Control objective:** Directory accounts are attributable to an authorized individual.

Two distinct conditions, two separate findings:

1. **Blank employee identifier** — service, shared, vendor accounts. Expected to exist; the question is whether they are governed.
2. **Populated identifier with no matching HR record** — a true orphan. Either a data integrity problem or an account outliving its personnel record.

```powershell
# --- Reference list: the FULL roster, active and terminated ---
# LA-01 used terminated IDs only. Here an account is attributable
# if it matches anyone on record.
$allEmpIDs = $pop.EmployeeID
$allEmpIDs.Count                                # 487

# --- Accounts matching no HR record ---
$orphans = $ad | Where-Object { $_.EmployeeID -notin $allEmpIDs }
$orphans.Count                                  # 16

# --- Separate the two conditions ---
$blankID = $orphans | Where-Object { $_.EmployeeID -eq "" }
$blankID.Count                                  # 12

$trueOrphans = $orphans | Where-Object { $_.EmployeeID -ne "" }
$trueOrphans.Count                              # 4 — must sum to 16

# --- Inspect the orphans individually ---
$trueOrphans |
    Select-Object SamAccountName, DisplayName, EmployeeID, Department, PrivilegedGroup, LastLogonDate |
    Format-Table

# --- Retain evidence: two workpapers, two owners ---
$blankID     | Export-Csv "$auditPath\workpapers\WP-LA-02-01_Non-Attributable_Accounts.csv" -NoTypeInformation
$trueOrphans | Export-Csv "$auditPath\workpapers\WP-LA-02-02_Orphaned_Accounts.csv" -NoTypeInformation
```

**Results:** 16 unattributable accounts of 500. 12 blank identifier, 4 true orphans.

### Technique notes

- **`-notin` is `-in` reversed.** LA-01 asked which accounts matched a list. LA-02 asks which match nothing.
- **Blank values pass a `-notin` test.** An empty identifier is not in the roster either, so the first filter captures both conditions at once. They are separated afterward.
- **Split filters must sum to the parent.** 12 + 4 = 16. A mismatch is a defect in the test, not a finding.

### Audit notes

- **A test path that has never returned a result has not been proven to work.** The first run of this test returned 0 true orphans — not because the control held, but because the test data contained no populated-but-unmatched identifiers. The branch had never executed. Four were seeded to exercise it.
- **Two conditions, two workpapers, two owners.** Non-attributable service accounts are a governance question for whoever owns them. Orphans are an access-revocation and data-integrity question.
- **Identifier format is evidence.** `LGY-4471` and `C-90233` are visibly foreign to the numbering scheme, making root cause easy to establish — acquisition, contractor. `E100482` matches the scheme exactly and is still unmatched. It looks correct and is not, which is why it survived.
- **The well-formed orphan is the hard finding.** A manual reviewer flags the odd formats and slides past the one that looks right.
- **Severity driver:** the escalation here was privileged database access on an account with no attributable owner — no manager, no recertification owner, nobody to revoke it.

---

## LA-03 — Dormant Accounts

**Control objective:** Inactive accounts are identified and disabled.

```powershell
# --- Convert text to real dates ---
# Import-Csv reads everything as text. The original LastLogonDate
# column is left untouched; LogonDate is added beside it.
$ad = $ad | Select-Object *, @{
    Name       = "LogonDate"
    Expression = { [datetime]$_.LastLogonDate }
}

# --- Set the threshold ---
# As-of date is fixed, never "today" — a script anchored to the
# current date returns different results on different days and
# cannot be reperformed.
$asOfDate    = [datetime]"08/29/2026"
$dormantDays = 90
$cutoff      = $asOfDate.AddDays(-$dormantDays)
$cutoff                                         # 05/31/2026

# --- Identify dormant accounts ---
# -lt finds logon dates EARLIER than the cutoff.
# The Enabled condition keeps properly disabled accounts out; a
# disabled dormant account is the control working, not failing.
$dormant = $ad | Where-Object {
    $_.Enabled -eq "TRUE" -and $_.LogonDate -lt $cutoff
}
$dormant.Count                                  # 64

# --- Add inactivity age ---
$dormant = $dormant | Select-Object *, @{
    Name       = "DaysInactive"
    Expression = { ($asOfDate - $_.LogonDate).Days }
}

# --- Stratify by age, longest first ---
$dormant |
    Sort-Object DaysInactive -Descending |
    Select-Object SamAccountName, DisplayName, Department, DaysInactive, PrivilegedGroup -First 15 |
    Format-Table

# --- Assess severity: privileged access ---
$dormantPriv = $dormant | Where-Object { $_.PrivilegedGroup -ne "" }
$dormantPriv.Count                              # 11

# --- Retain evidence ---
$dormant     | Sort-Object DaysInactive -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-03-01_Dormant_Accounts.csv" -NoTypeInformation
$dormantPriv | Sort-Object DaysInactive -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-03-02_Dormant_Privileged_Accounts.csv" -NoTypeInformation
```

**Results:** 64 enabled accounts with no authentication activity exceeding 90
days, of 500. 11 of the 64 carry privileged group membership. Longest
inactivity 922 days.

### Technique notes

- **The silent failure.** Unconverted text compares alphabetically.
  `"09/15/2024" -lt "07/23/2026"` returns `False` — it compares character by
  character, hits 9 against 7, and never reaches the year. No error is raised.
- **Fixed as-of date, not `Get-Date`.** A test anchored to the current date
  produces different figures on different days and cannot be reperformed.
- **Threshold as a named container.** `$dormantDays = 90` changes to 60 in one
  place when the client's policy differs, and the threshold is visible to a
  reviewer rather than buried in a comparison.
- **Diagnostics are removed before the script is finished.** The `.GetType()`
  lines proved the conversion worked and were deleted. A reviewer should not
  have to work out which output is evidence.
- **`-First` belongs to `Select-Object`.** On `Format-Table` it errors with "a
  parameter cannot be found that matches parameter name 'First'" — the
  signature of an option attached to the wrong cmdlet.

### Audit notes

- **Dormancy concentrates privilege.** 11 of 64 dormant accounts held
  privileged groups — roughly one in six, against a far lower rate across the
  population. Accounts nobody uses are accounts nobody reviews.
- **Service account in Domain Admins, 552 days idle.** Either the job stopped
  running unnoticed or it never required that privilege. Both point to
  privilege granted at provisioning and never revisited.
- **Vendor account in ERP_Superuser, 540 days idle.** Third-party access
  outliving the engagement it was provisioned for.
- **Cross-reference dormant privileged user accounts against the LA-01
  terminated set** before writing them up. A dormant privileged account
  belonging to current personnel is a different finding from one belonging to a
  separated individual.
- **Age drives severity.** 91 days is a hygiene observation. 922 days on an
  enabled account is a standing exposure with no business owner.

---

## LA-04 — Privileged Access Without MFA

**Control objective:** Privileged access requires multi-factor authentication.

```powershell
# --- Privileged population ---
# No HR roster. The test lives entirely inside the directory extract.
$privileged = $ad | Where-Object { $_.PrivilegedGroup -ne "" }
$privileged.Count                               # 53 of 500

# --- Accounts without MFA ---
$noMFA = $privileged | Where-Object { $_.MFAEnrolled -eq "FALSE" }
$noMFA.Count                                    # 19

# --- Review ---
$noMFA |
    Select-Object SamAccountName, DisplayName, Department, AccountType, PrivilegedGroup |
    Format-Table

# --- Stratify by account type ---
$noMFA | Group-Object AccountType | Sort-Object Count -Descending | Format-Table Name, Count

# --- Retain evidence ---
$privileged | Export-Csv "$auditPath\workpapers\WP-LA-04-01_Privileged_Population.csv" -NoTypeInformation
$noMFA      | Export-Csv "$auditPath\workpapers\WP-LA-04-02_Privileged_No_MFA.csv" -NoTypeInformation
```

**Results:** 53 privileged accounts of 500. 19 without MFA enrollment (36%).

By account type: User 16, Shared 2, Service 1.

By privileged group: ERP_Superuser 5, Domain Admins 5, Firewall_Admins 4,
Backup Operators 3, Server Operators 2.

### Technique notes

- Single-population test. LA-01 through LA-03 compared two populations or
  tested against a date; this one tests attributes within one extract, so the
  population definition carries the judgment.
- `-eq "FALSE"` compares against text. `Import-Csv` reads the column as the
  word FALSE, not as a true/false value.
- `AccountType` included in the output so service and shared accounts are
  distinguishable from user accounts.

### Audit notes

- Population definition is the exposure. Scoping "privileged" to the groups
  present in the extract understates it where privilege is also granted
  outside group membership.
- Shared and service accounts in the no-MFA set are a separate remediation
  path from user accounts; MFA applicability differs.
- Domain Admins and ERP_Superuser account for 10 of the 19.

---

## LA-05 — Stale Credentials

**Control objective:** Credentials are rotated in accordance with policy.

```powershell
# --- Convert text to a real date ---
$ad = $ad | Select-Object *, @{
    Name       = "PwdSetDate"
    Expression = { [datetime]$_.PasswordLastSet }
}

# --- Threshold ---
$asOfDate  = [datetime]"08/29/2026"
$maxPwdAge = 365
$cutoff    = $asOfDate.AddDays(-$maxPwdAge)
$cutoff                                         # 08/29/2025

# --- Identify stale credentials ---
$stalePwd = $ad | Where-Object {
    $_.Enabled -eq "TRUE" -and $_.PwdSetDate -lt $cutoff
}
$stalePwd.Count                                 # 62

# --- Add credential age ---
$stalePwd = $stalePwd | Select-Object *, @{
    Name       = "DaysSincePwdSet"
    Expression = { ($asOfDate - $_.PwdSetDate).Days }
}

# --- Sort by age, oldest first ---
$stalePwd |
    Sort-Object DaysSincePwdSet -Descending |
    Select-Object SamAccountName, DisplayName, Department, AccountType, DaysSincePwdSet, PrivilegedGroup -First 15 |
    Format-Table

# --- Privileged subset ---
$stalePwdPriv = $stalePwd | Where-Object { $_.PrivilegedGroup -ne "" }
$stalePwdPriv.Count                             # 9

# --- Retain evidence ---
$stalePwd     | Sort-Object DaysSincePwdSet -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-05-01_Stale_Credentials.csv" -NoTypeInformation
$stalePwdPriv | Sort-Object DaysSincePwdSet -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-05-02_Stale_Credentials_Privileged.csv" -NoTypeInformation
```

**Results:** 62 enabled accounts with credentials past the 365-day threshold,
of 500. 9 carry privileged group membership. Longest credential age 3,471 days.

By account type: User 54, Service 5, Shared 3.

By privileged group: Backup Operators 2, SQL_DBA_Admins 2, Domain Admins 2,
Firewall_Admins 1, ERP_Superuser 1, Server Operators 1.

### Technique notes

- Structurally identical to LA-03. Convert the text date, set a fixed
  threshold, filter enabled accounts against it, add the age, stratify.
- `Format-Table` controls display shape only. Removing it prints the same
  records as stacked lists; removing it without also removing the trailing `|`
  raises "An empty pipe element is not allowed."
- The `Enabled` condition is carried over for the same reason as LA-03. A
  disabled account with an old password is not an exception.

### Audit notes

- The longest credential age exceeds nine years on an enabled account.
- `vendor_acme_sup` appears in LA-03, LA-04, and LA-05 workpapers: dormant,
  no MFA, and stale credential, holding ERP_Superuser throughout.
- Service and shared accounts account for 8 of 62. Rotation practicality
  differs for non-interactive accounts and is a separate remediation path.

---

## LA-06 — Segregation of Privileged Access (Blocked)

**Control objective:** Privileged access is appropriately segregated.

Not tested. The directory extract carries one value per account in
`PrivilegedGroup`, so no account can show conflicting memberships. Confirmed
against the extract: 53 privileged rows, none holding more than one group.
Testing requires a group membership extract with one row per account-group
pair, the same extract LA-11 needs.

---

## LA-07 — Privileged Access Scope

**Control objective:** Privileged access is limited to those requiring it.

```powershell
# --- Populations: numerator and denominator from the same base ---
$enabled = $ad | Where-Object { $_.Enabled -eq "TRUE" }
$enabled.Count                                  # 417

$privileged = $ad | Where-Object {
    $_.Enabled -eq "TRUE" -and $_.PrivilegedGroup -ne ""
}
$privileged.Count                               # 48

# --- Proportion ---
$privPct = [math]::Round(($privileged.Count / $enabled.Count) * 100, 1)
$privPct                                        # 11.5

# --- Stratify by department ---
$privileged | Group-Object Department | Sort-Object Count -Descending | Format-Table Name, Count

# --- Accounts outside expected departments ---
# The judgment of which departments warrant privilege sits in one line.
$expectedDepts = @("Information Technology")

$outOfScope = $privileged | Where-Object { $_.Department -notin $expectedDepts }
$outOfScope.Count                               # 20

$outOfScope |
    Sort-Object Department |
    Select-Object SamAccountName, DisplayName, Department, AccountType, PrivilegedGroup |
    Format-Table

# --- Retain evidence ---
$privileged | Export-Csv "$auditPath\workpapers\WP-LA-07-01_Privileged_Enabled_Population.csv" -NoTypeInformation
$outOfScope | Sort-Object Department |
    Export-Csv "$auditPath\workpapers\WP-LA-07-02_Privileged_Out_Of_Scope.csv" -NoTypeInformation
```

**Results:** 48 enabled accounts hold privileged group membership, 11.5% of
417 enabled accounts. 20 sit outside Information Technology.

By department: Information Technology 28, Engineering 6, Finance 4,
Operations 4, Sales 3, Customer Service 1, Legal & Compliance 1, Marketing 1.
Reconciles to 48.

Outside IT, by privileged group: Firewall_Admins 4, Server Operators 4,
Backup Operators 4, Domain Admins 3, SQL_DBA_Admins 3, ERP_Superuser 2.
By account type: User 18, Shared 2.

### Technique notes

- Numerator and denominator come from the same population. The first draft
  counted privileged accounts across all 500 (53, including disabled) against
  an enabled denominator; both sides are now restricted to enabled accounts.
- `@( )` builds a list. `-notin` tests each department against it.
- `/` divides, `*` multiplies, `[math]::Round(value, 1)` rounds to one
  decimal place.
- `Sort-Object` must come before `Format-Table`. `Format-Table` converts data
  to display output; nothing after it can read the columns.
- After `Group-Object`, each row is a bucket: `Name` is the grouped value,
  `Count` the number of records in it.
- Container names ignore capitalization. `$outofScope` and `$outOfScope` are
  the same container.

### Audit notes

- `$expectedDepts` holds the scoping judgment. It is visible to a reviewer and
  changes in one line without touching the filter.
- Department is a proxy for role. Job title from the HR roster would sharpen
  the test; that requires joining the two extracts on `EmployeeID`.
- Domain Admins is held outside IT by accounts in Engineering, Sales, and
  Operations, including a shared training-room account.

---

## LA-08 — Provisioning Timeliness

**Control objective:** Access is provisioned timely upon hire.

```powershell
# --- Active personnel with no directory account ---
$active = $pop | Where-Object { $_.EmploymentStatus -eq "Active" }
$active.Count                                   # 396

$adIDs = $ad.EmployeeID
$adIDs.Count                                    # 500

$noAccount = $active | Where-Object { $_.EmployeeID -notin $adIDs }
$noAccount.Count                                # 3

# --- Lookup table: EmployeeID -> HR record ---
$hrLookup = @{}
foreach ($emp in $pop) {
    $hrLookup[$emp.EmployeeID] = $emp
}
$hrLookup.Count                                 # 487

# --- Accounts with a matching HR record ---
$matched = $ad | Where-Object { $hrLookup.ContainsKey($_.EmployeeID) }
$matched.Count                                  # 484

# --- Attach hire date, measure the gap ---
$matched = $matched | Select-Object *, @{
    Name       = "HireDate"
    Expression = { [datetime]$hrLookup[$_.EmployeeID].HireDate }
}
$matched = $matched | Select-Object *, @{
    Name       = "DaysToProvision"
    Expression = { ([datetime]$_.WhenCreated - $_.HireDate).Days }
}

$matched | Measure-Object DaysToProvision -Minimum -Maximum   # -3 to 12

# --- Threshold ---
$maxProvisionDays = 5
$late  = $matched | Where-Object { $_.DaysToProvision -gt $maxProvisionDays }
$early = $matched | Where-Object { $_.DaysToProvision -lt 0 }

# --- Reconciliation ---
$untestable   = $ad.Count - $matched.Count
$withinPolicy = $matched.Count - $late.Count - $early.Count
"Population $($ad.Count) = Tested $($matched.Count) + Untestable $untestable"
"Tested $($matched.Count) = Within policy $withinPolicy + Late $($late.Count) + Early $($early.Count)"

# --- Retain evidence ---
$noAccount | Export-Csv "$auditPath\workpapers\WP-LA-08-01_Active_No_Account.csv" -NoTypeInformation
$late      | Sort-Object DaysToProvision -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-08-02_Provisioned_Late.csv" -NoTypeInformation
$early     | Sort-Object DaysToProvision |
    Export-Csv "$auditPath\workpapers\WP-LA-08-03_Provisioned_Before_Hire.csv" -NoTypeInformation
```

**Results:** 3 of 396 active employees have no directory account. Of 500
accounts, 484 match an HR record and were tested; 16 are untestable, which
ties to the 16 unattributable accounts in LA-02.

```
Population 500 = Tested 484 + Untestable 16
Tested 484 = Within policy 177 + Late 218 + Early 89
```

Gap from hire to account creation ranges from -3 to 12 days.

### Technique notes

- First test joining two extracts record by record. `@{}` builds an empty
  lookup table; `foreach` files each HR record under its EmployeeID;
  `$hrLookup[$_.EmployeeID]` retrieves the matching record for each account.
- `.ContainsKey()` separates accounts that can be tested from those that
  cannot, so untestable records are counted rather than silently dropped.
- A hard-coded spot check (`$hrLookup["E104763"].HireDate`) confirmed the
  lookup returned the right record, then was removed from the script.
- `Measure-Object -Minimum -Maximum` shows the range before a threshold is set.
- `$( )` inside double quotes evaluates an expression and inserts the result.
  Without it, `"$ad.Count"` prints the container followed by the literal text
  `.Count`.
- First reconciliation line in the toolkit stating
  population = tested + untestable, and tested = within policy + exceptions.

### Audit notes

- Three active employees with no account fall into two different conditions.
  One was hired 05/26/2026, roughly three months before the as-of date. Two
  were hired in 2016 and 2022 and have never had an account, which points to
  roles not requiring directory access or to a record-matching problem rather
  than a provisioning delay.
- Accounts created before the hire date are a separate condition from late
  provisioning: access existed before employment began.
- Test data limitation: the synthetic extract spreads creation dates evenly
  from 3 days before to 12 days after hire rather than seeding a small set of
  exceptions, so the late and early counts move directly with the threshold
  and should not be read as a realistic exception rate.

---

## Random Selection (reference — not yet run)

**Audit purpose:** Converts a judgmental selection into a reproducible, reperformable one.

```powershell
$sample = $pop | Get-Random -Count 25 -SetSeed 20260829
$sample | Export-Csv "$auditPath\sample_25.csv" -NoTypeInformation
```

`-SetSeed` is the audit-relevant piece — anyone re-running with the same seed gets the same 25 items. That is your reperformance evidence.

---

## Test Data Reference

`hr_roster.csv` — 487 employees, 91 terminated
`ad_user_accounts.csv` — 500 accounts, including service, shared, vendor, and orphaned accounts

Seeded exception areas:
1. Terminated users with enabled accounts — **LA-01, 24 found**
2. Accounts not attributable to an HR record — **LA-02, 16 found (12 blank, 4 orphaned)**
3. Dormant accounts exceeding 90 days — **LA-03, 64 found (11 privileged)**
4. Privileged accounts without MFA enrollment — **LA-04, 19 found**
5. Stale credentials past 365 days — **LA-05, 62 found (9 privileged)**
6. Segregation of duties conflicts across privileged groups — **LA-06, blocked: one group per account in the extract**
7. Privileged access outside expected departments — **LA-07, 20 found**
8. Provisioning timeliness — **LA-08, 3 active with no account; 218 late, 89 before hire (5-day threshold)**

See `control-matrix.md` for the full roadmap and the extracts required to unblock
the remaining domains.
