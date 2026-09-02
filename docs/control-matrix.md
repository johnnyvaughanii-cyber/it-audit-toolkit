# Control Matrix

Ongoing. Control objectives are added as they are built, organized by ITGC
domain. Each maps to one test script and one or more workpapers.

Current population as of: 08/29/2026
Populations: 487 HR records · 500 directory accounts

**Status key:** Complete · In progress · Ready (test data exists) ·
Blocked (needs additional extract)

---

## LA — Logical Access

Identity, authentication, and authorization. The largest domain, and the one
most examined in SOX ITGC and FFIEC engagements.

| ID | Control objective | Test method | Status |
|---|---|---|---|
| LA-01 | Access is revoked timely upon separation | Full-population reconciliation of HR termination listing to directory extract | Complete |
| LA-02 | Directory accounts are attributable to an authorized individual | Accounts with no corresponding HR record; classify service, shared, vendor | Complete |
| LA-03 | Inactive accounts are identified and disabled | Enabled accounts with no authentication activity exceeding 90 days | Ready |
| LA-04 | Privileged access requires multi-factor authentication | Privileged group membership tested for MFA enrollment | Ready |
| LA-05 | Credentials are rotated in accordance with policy | Password age exceeding 365 days on enabled accounts | Ready |
| LA-06 | Privileged access is appropriately segregated | Conflicting privileged group memberships held by a single account | Ready |
| LA-07 | Privileged access is limited to those requiring it | Administrator count as a proportion of population; reasonableness against role | Ready |
| LA-08 | Access is provisioned timely upon hire | Active personnel with no corresponding directory account | Ready |
| LA-09 | Shared and generic accounts are governed | Shared accounts tested for named owner, documented purpose, credential rotation | Ready |
| LA-10 | Service accounts are appropriately restricted | Service accounts tested for interactive logon activity and password age | Ready |
| LA-11 | Effective access reflects intended access | Nested group membership resolved to effective privilege | Blocked — needs group membership extract |
| LA-12 | Access is adjusted upon role change | Accumulated entitlements across prior and current department | Blocked — needs transfer history |
| LA-13 | Password policy is configured per standard | Domain policy settings compared to stated standard | Blocked — needs policy export |
| LA-14 | User access reviews are performed and evidenced | Recertification completeness, reviewer independence, exception closure | Blocked — needs UAR records |
| LA-15 | External and guest access is time-bound | Vendor and contractor accounts tested for expiration date | Blocked — needs account attributes |

---

## CM — Change Management

Whether changes reaching production were authorized, tested, and approved by
someone other than the developer.

| ID | Control objective | Test method | Status |
|---|---|---|---|
| CM-01 | Production changes are authorized | Deployment records reconciled to approved change tickets | Blocked — needs change log |
| CM-02 | Changes are approved prior to implementation | Approval timestamp compared to deployment timestamp | Blocked |
| CM-03 | Emergency changes receive retrospective approval | Emergency-flagged changes tested for post-implementation approval within policy window | Blocked |
| CM-04 | Developers cannot deploy their own changes | Requester compared to deployer on each change record | Blocked |
| CM-05 | Developer access to production is restricted | Development personnel tested against production access groups | Ready — uses AD extract |

---

## OP — Operations and Monitoring

| ID | Control objective | Test method | Status |
|---|---|---|---|
| OP-01 | Privileged activity is logged | Privileged accounts tested for corresponding audit log entries | Blocked — needs log extract |
| OP-02 | Authentication anomalies are detectable | Failed logon concentration, after-hours privileged access | Blocked |
| OP-03 | Logs are retained per policy | Earliest available log entry compared to retention standard | Blocked |

---

## BU — Backup and Recovery

| ID | Control objective | Test method | Status |
|---|---|---|---|
| BU-01 | Backup jobs complete successfully | Job success rate over the period; failures tested for remediation | Blocked — needs backup job log |
| BU-02 | Restoration is periodically tested | Restore test evidence within policy interval | Blocked |
| BU-03 | Retention meets policy | Retained backup sets compared to stated retention | Blocked |

---

## CF — Configuration and Endpoint

| ID | Control objective | Test method | Status |
|---|---|---|---|
| CF-01 | Systems are patched within policy windows | Patch level compared to release date against SLA | Blocked — needs endpoint inventory |
| CF-02 | Stale computer objects are removed | Computer accounts with no activity exceeding policy threshold | Blocked — needs computer object extract |
| CF-03 | Unsupported operating systems are inventoried | OS version compared to vendor support lifecycle | Blocked |
| CF-04 | Local administrator rights are restricted | Workstation local admin membership | Blocked |

---

## VM — Vendor and Third-Party

| ID | Control objective | Test method | Status |
|---|---|---|---|
| VM-01 | Vendor access is inventoried and owned | Vendor accounts tested for named internal owner | Ready — partial |
| VM-02 | Vendor assessments are current | Assessment date compared to required interval | Blocked — needs vendor register |

---

## Framework references

| Framework | Reference |
|---|---|
| SOX ITGC | Access to Programs and Data; Program Change; Computer Operations |
| FFIEC IT Examination Handbook | Information Security; Operations; Business Continuity |
| COBIT 5 | DSS05 Manage Security Services; BAI06 Manage Changes; DSS04 Manage Continuity |
| ISACA ITAF | Evidence, documentation, and reperformance standards |

---

## Test data roadmap

Objectives marked Blocked require extracts that do not yet exist. Synthetic
extracts will be generated as each domain is built:

| Extract | Unlocks |
|---|---|
| Group membership (nested) | LA-11 |
| Transfer and role change history | LA-12 |
| Domain password policy export | LA-13 |
| UAR recertification records | LA-14 |
| Change ticket register | CM-01 through CM-04 |
| Authentication event log | OP-01 through OP-03 |
| Backup job log | BU-01 through BU-03 |
| Endpoint and computer object inventory | CF-01 through CF-04 |
| Vendor register | VM-02 |

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
header. Results are not continuous monitoring output and are not represented
as such.

**A zero-exception result is still a result.** A test that returns nothing is
documented with its population, method, and outcome. No exceptions found is a
conclusion; not running the test is not.

**Exceptions are not conclusions.** A flagged record is a condition requiring
investigation. Whether it constitutes a control deficiency depends on
management's response and any compensating control, neither of which lives in
the extract.
