# Control Matrix — Logical Access

Scope: on-premises Active Directory. Each control objective maps to one test
script and one or more workpapers.

Population as of: 08/29/2026
Populations: 487 HR records · 496 directory accounts

---

| ID | Control objective | Test method | Script | Workpaper | Status |
|---|---|---|---|---|---|
| LA-01 | Logical access is revoked timely upon separation | Full-population reconciliation of HR termination listing to directory extract | `Test-TerminatedAccess.ps1` | WP-LA-01, WP-LA-02 | Complete |
| LA-02 | Directory accounts are attributable to an authorized individual | Identify accounts with no corresponding HR record; classify service, shared, and vendor accounts | — | — | Not started |
| LA-03 | Inactive accounts are identified and disabled | Enabled accounts with no authentication activity exceeding 90 days | — | — | Not started |
| LA-04 | Privileged access requires multi-factor authentication | Privileged group membership tested for MFA enrollment | — | — | Not started |
| LA-05 | Credentials are rotated in accordance with policy | Password age exceeding 365 days on enabled accounts | — | — | Not started |
| LA-06 | Privileged access is appropriately segregated | Conflicting privileged group memberships held by a single account | — | — | Not started |

---

## Framework references

| Framework | Reference |
|---|---|
| SOX ITGC | Access to Programs and Data |
| FFIEC IT Examination Handbook | Information Security — user access management, authentication |
| COBIT 5 | DSS05.04 Manage user identity and logical access |
| ISACA ITAF | Evidence, documentation, and reperformance standards |

---

## Testing conventions

**Full population, not sample.** Where the population is an extract and the
test is a comparison, sampling is an inherited constraint rather than one the
data imposes. Sampling is used only where the test requires inspection of
evidence outside the extract.

**Count reconciliation at each transformation.** Every filtering step
re-states its record count. A population that changes size unexpectedly
between steps is a defect in the test, not a finding.

**Read-only.** Every cmdlet used is a read, a filter, or a write to the
workpaper folder. No script in this repository creates, modifies, disables,
or deletes a directory object.

**Point-in-time.** Each test states its population as-of date in the file
header. Results are not continuous monitoring output and should not be
represented as such.

**Exceptions are not conclusions.** A flagged record is a condition requiring
investigation. Whether it constitutes a control deficiency depends on
management's response and any compensating control, neither of which lives
in the extract.
