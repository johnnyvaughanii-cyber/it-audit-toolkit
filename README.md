# IT Audit Toolkit

Scripted, full-population control testing for on-premises Active Directory.
PowerShell. Read-only.

This is the audit side of my work. Testing whether controls operate, not
building them. My compliance-as-code and GRC engineering projects live in
separate repositories, deliberately — an auditor cannot independently test a
control they implemented, and the separation here reflects that.

---

## Posture

Audit is a detective function operating at a point in time against a defined
population. That shapes everything in this repository:

**Read-only, without exception.** Every cmdlet used is a read, a filter, or a
write to the workpaper folder. Nothing here creates, modifies, disables, or
deletes a directory object. This matters when the auditee's security team
reviews what you are proposing to run in their environment.

**Full population where the data permits it.** A judgmental sample of 25
terminations supports a conclusion about 25 terminations. Where the population
is an extract and the test is a comparison, sampling is a constraint inherited
from manual testing rather than one the data imposes.

**Reperformable.** A reviewer runs the same script against the same extract
and reaches the same result. The selection methodology stops being a narrative
in a memo and becomes an executable procedure.

**Point-in-time.** Each test states its population as-of date. This is not
continuous monitoring and is not represented as such.

Speed is not on this list. It is real, and it is the weakest argument.

---

## Structure

```
tests/        One script per control objective
docs/         Control matrix and test development log
data/         Synthetic test populations
workpapers/   Generated output (not committed)
```

**`docs/control-matrix.md`** maps each control objective to its test method,
script, workpaper, and framework reference. Start there.

**`docs/control-test-log.md`** records each test as built: the script as run,
the technique notes behind it, and the reasoning for the method chosen.

---

## Coverage

| ID | Control objective | Status |
|---|---|---|
| LA-01 | Access revoked timely upon separation | Complete |
| LA-02 | Accounts attributable to an authorized individual | Complete |
| LA-03 | Inactive accounts identified and disabled | Complete |
| LA-04 | Privileged access requires MFA | Complete |
| LA-05 | Credentials rotated per policy | Complete |
| LA-06 | Privileged access appropriately segregated | Not started |

---

## LA-01 results against the test data

| Measure | Result |
|---|---|
| HR population | 487 |
| Directory accounts | 500 |
| Terminated personnel | 91 |
| Terminated retaining enabled accounts | 24 (26%) |
| Of those, holding privileged access | 5 |

The privileged subset included Domain Admins membership and one Backup
Operators account with no MFA enrollment.

Backup Operators is routinely under-weighted because the name reads as
custodial. The group can read and restore files regardless of the permissions
set on them — it bypasses file-level access controls by design. With no MFA,
there is no compensating control to fall back on.

---

## Test data

**The CSVs in `data/` are synthetic.** No real personnel records, directory
extracts, or client data appear in this repository, and none will.

This is stated plainly because it should be. An auditor who publishes a public
repository containing anything resembling a real directory extract has
demonstrated a judgment failure more serious than any control weakness the
scripts could find.

Exceptions were deliberately seeded so the tests have something to detect.

---

## Running it

Windows PowerShell 5.1 or PowerShell 7+. No modules required.

1. Clone the repository
2. Open a script in `tests/`
3. Edit `$auditPath` to point at your local copy
4. Run the file

Output writes to `workpapers/`.

---

## Limitations

Synthetic data only. These scripts have not been run in a live engagement and
have not been peer-reviewed.

Tests read from CSV extracts rather than querying Active Directory directly.
An extract introduces a completeness question a live query does not — the
auditor is relying on someone else's export. Extract validation is not
addressed here yet.

Exceptions are conditions requiring investigation, not conclusions. Whether a
flagged record constitutes a control deficiency depends on management's
response and any compensating control, neither of which lives in the extract.

No test coverage of the scripts themselves.

---

## Related work

Compliance-as-code and evidence pipeline projects are maintained separately:
[portfolio.johnnyvaughanllc.com](https://portfolio.johnnyvaughanllc.com)
