# PowerShell Command Dictionary — IT Audit

Running reference. Updated after each control objective.

Last updated: LA-03 complete — Dormant Accounts

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
| `[0]` | Pick an item by position. Counting starts at zero, so `[0]` is the first. |
| `*` | All columns. |
| `@{ }` | A definition block with labeled parts, used to build a new column. |
| `[datetime]` | Convert the text that follows into a real date. |
| `( )` | Do what is inside these first, before anything else. |

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
| `-lt` | Less than | yes |
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
| `-First n` | `Select-Object` | Only the first n rows. Belongs to `Select-Object`, not `Format-Table`. |
| `-Descending` | `Sort-Object` | Largest to smallest. |
| `-NoTypeInformation` | `Export-Csv` | Drops a junk header line Excel does not want. |
| `-Count 25` | `Get-Random` | Pull 25 items. |
| `-SetSeed 20260829` | `Get-Random` | Fixes the randomness so it repeats identically. |

---

## Working with Dates

`Import-Csv` reads every value as **text**, not as a date. Text comparisons
sort alphabetically, so a date test built on unconverted text returns a wrong
answer with no error.

| Piece | Means |
|---|---|
| `.GetType().Name` | Ask what kind of thing a value actually is. Returns `String` before conversion, `DateTime` after. |
| `[datetime]"08/29/2026"` | Convert text into a real date. |
| `.AddDays(n)` | Move a date forward by n days. Negative moves backward. |
| `$dateA - $dateB` | Subtract two dates. Returns a span of time. |
| `.Days` | From a span of time, pull just the whole number of days. |

**Add a converted column rather than replacing the original.** The source value
stays visible in the workpaper beside the converted one, so the transformation
is documented rather than hidden.

```powershell
$ad = $ad | Select-Object *, @{
    Name       = "LogonDate"
    Expression = { [datetime]$_.LastLogonDate }
}
```

**With dates, earlier is smaller.** `-lt` finds dates further in the past.
Plain English runs opposite to the operator: "more than 90 days inactive" is a
bigger number of days but a smaller date. Writing `-gt` by mistake runs cleanly
and returns every *recently active* account.

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

## Git

Version control. Run these in the VS Code terminal, from the repository folder.

### One-time setup

| Command | Does |
|---|---|
| `git --version` | Confirm git is installed. |
| `git config --global user.name "Name"` | Set the name attached to commits. `--global` applies to every repository on the machine. |
| `git config --global user.email "address"` | Set the email. Must match the GitHub account or commits will not link to the profile. |

### Starting a repository

| Command | Does |
|---|---|
| `git init` | Begin tracking this folder. Creates a hidden `.git` folder. |
| `git branch -M main` | Rename the current branch to `main`. Git's old default is `master`; GitHub expects `main`. |
| `git remote add origin <url>` | Register the GitHub address. `origin` is the conventional nickname, not a keyword. |
| `git remote -v` | List registered addresses. Should show one `fetch` and one `push` line. |

Create the repository on GitHub with **no** README, .gitignore, or license.
Initializing on both ends creates two histories with no shared starting point,
and the first push is rejected.

### The routine

| Command | Does |
|---|---|
| `git add .` | Stage everything in this folder and below. Staging is a holding step; nothing is recorded yet. |
| `git status` | Show what is staged. Read this before every commit. |
| `git commit -m "message"` | Record the staged files as a permanent snapshot. Quotes are required. |
| `git push` | Send commits to GitHub. Works bare after the first `push -u origin main`. |
| `git log --oneline -3` | Show the last three commits. |

After the first push, the routine is three commands: `git add .`, `git commit -m "..."`, `git push`.

**Read `git status` before committing.** It is the last checkpoint before files
become part of a public repository, and the same instinct as reviewing an
extract before testing it. It is the step that keeps client data out.

### Checking and undoing

| Command | Does |
|---|---|
| `git diff --stat <file>` | Summarize what changed in a file. |
| `git diff --ignore-all-space --numstat <file>` | Same, ignoring whitespace. Empty output means only line endings changed. |
| `git checkout -- <file>` | Discard local changes to a file and restore the committed version. |
| `git add --renormalize .` | Re-apply line-ending rules to every tracked file after changing `.gitattributes`. |

### Credentials

GitHub does not accept account passwords. When prompted for one, supply a
personal access token instead: GitHub → Settings → Developer settings →
Personal access tokens → Fine-grained, with Contents set to read/write.

### `.gitignore`

Lists what git should not track. Generated output does not belong in a
repository — a committed workpaper goes stale and drifts from what the script
actually produces.

```
workpapers/*
!workpapers/.gitkeep
```

`!` means "except this." Git tracks files, not folders, so an empty folder does
not exist to git. `.gitkeep` is a zero-byte placeholder that keeps the folder
alive through a clone. The name is convention, not a git feature.

### `.gitattributes`

Controls line-ending handling. Windows ends lines with two characters (CRLF),
Linux and Mac with one (LF). Without rules, files rewritten by Windows show as
fully modified when nothing in them changed.

```
*.ps1  text eol=crlf
*.md   text eol=lf
data/** -text
```

`-text` tells git to leave population extracts byte-for-byte, so their hashes
stay stable. In an audit repository, a data file reporting as modified should
mean the population changed.

### Other commands used

| Command | Does |
|---|---|
| `cd <path>` | Move into a folder. |
| `Remove-Item <file>` | Delete a file. |

`.git\index.lock` is git's "busy" marker. It normally deletes itself. If a
command is interrupted and leaves it behind, git refuses to run until it is
removed.

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
    Export-Csv "$auditPath\workpapers\WP-LA-05_Dormant_Accounts.csv" -NoTypeInformation
$dormantPriv | Sort-Object DaysInactive -Descending |
    Export-Csv "$auditPath\workpapers\WP-LA-06_Dormant_Privileged_Accounts.csv" -NoTypeInformation
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
4. Privileged accounts without MFA enrollment — next
5. Stale credentials past 365 days
6. Segregation of duties conflicts across privileged groups

See `control-matrix.md` for the full roadmap and the extracts required to unblock
the remaining domains.
