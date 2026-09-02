# PowerShell Command Dictionary — IT Audit

Running reference. Updated after each control objective.

Last updated: LA-02 complete — Orphaned Accounts

---

## Symbols

| Symbol | Means |
|---|---|
| `$name` | A container holding something. `$pop` = the population. |
| `=` | Put the thing on the right into the container on the left. |
| `\|` | "Then send that to." Chains steps left to right. |
| `.Count` | Attach to a container to get how many items are in it. |
| `.ColumnName` | Attach to a container to pull just that column out as a plain list. |
| `"...$var..."` | Double quotes swap the container's contents into the text. |
| `'...'` | Single quotes do NOT swap. Text stays literal. |
| `""` | Empty. Two quotes with nothing between them. |
| `-Something` | An option on a command. Always a dash, then a name. |
| `{ }` | Holds a test or a block of instructions. |
| `$_` | "The row I'm currently looking at." Only used inside `{ }`. |
| `#` | Everything after this on the line is a comment, ignored when run. |

---

## Cmdlets

PowerShell commands are called **cmdlets**. Always verb-noun.

| Cmdlet | Does |
|---|---|
| `Import-Csv` | Read a CSV into memory. |
| `Export-Csv` | Write results out to a CSV file. |
| `Select-Object` | Pick which columns to keep, or how many rows. |
| `Where-Object` | Keep only rows that pass a test. |
| `Group-Object` | Bucket rows by a column's value and count each bucket. |
| `Sort-Object` | Put rows in order by a column. |
| `Format-Table` | Display results as a grid instead of a stacked list. |
| `Get-Random` | Pull random items. |
| `Measure-Object` | Count, sum, or average a column. |
| `Get-Date` | Today's date, or convert text into a real date. |

---

## Comparison Operators

`=` is already taken (it means "put into container"), so comparisons get dashed words.

| Operator | Means | Used yet |
|---|---|---|
| `-eq` | Equals | yes |
| `-ne` | Does not equal | yes |
| `-in` | Is found somewhere in this list | yes |
| `-and` | Both conditions must be true | yes |
| `-gt` | Greater than | not yet |
| `-lt` | Less than | not yet |
| `-ge` | Greater than or equal to | not yet |
| `-le` | Less than or equal to | not yet |
| `-like` | Matches a pattern, using `*` as wildcard | not yet |
| `-notin` | Is not found in this list | yes |
| `-or` | Either condition can be true | not yet |
| `-not` | Reverses a condition | not yet |

---

## Options

| Option | Attaches to | Does |
|---|---|---|
| `-First 3` | `Select-Object` | Only the first 3 rows. |
| `-Descending` | `Sort-Object` | Largest to smallest. |
| `-NoTypeInformation` | `Export-Csv` | Drops a junk header line Excel does not want. |
| `-Count 25` | `Get-Random` | Pull 25 items. |
| `-SetSeed 20260829` | `Get-Random` | Fixes the randomness so it repeats identically. |

---

## VS Code

| Action | How |
|---|---|
| Run the whole file | Play button, top right |
| Extensions panel | `Ctrl+Shift+X` |
| Save | `Ctrl+S` |

Notes:
- File must be saved as `.ps1` for the PowerShell extension to activate.
- Bottom-right status bar should read `PowerShell`.
- `F8` is remapped in this environment ("next problem") — use the play button.
- Play button runs the entire file top to bottom, so setup lines must stay in place.

---

# Lesson Log

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
$exceptions     | Export-Csv "$auditPath\WP-LA-01_Terminated_Enabled_Accounts.csv" -NoTypeInformation
$privExceptions | Export-Csv "$auditPath\WP-LA-02_Privileged_Terminated_Accounts.csv" -NoTypeInformation
```

**Results:** 24 of 91 terminated users retained enabled accounts (26% failure rate). 5 of those 24 held privileged group membership, including Domain Admins. One Backup Operators account had no MFA enrollment.

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
- **Two-tier finding here:** Domain Admins retained post-separation, and an unenrolled privileged account. Different remediation owners, different timelines.

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
$blankID     | Export-Csv "$auditPath\workpapers\WP-LA-03_Non-Attributable_Accounts.csv" -NoTypeInformation
$trueOrphans | Export-Csv "$auditPath\workpapers\WP-LA-04_Orphaned_Accounts.csv" -NoTypeInformation
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
3. Dormant accounts exceeding 90 days — next
4. Privileged accounts without MFA enrollment
5. Stale credentials past 365 days
6. Segregation of duties conflicts across privileged groups

See `control-matrix.md` for the full roadmap and the extracts required to unblock
the remaining domains.
