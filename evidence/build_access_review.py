"""Build evidence/access-review-Q4-2026.xlsx (EXAMPLE DATA).

All people, IDs, tickets and dates are fictional and match the Terraform defaults in
terraform/02-identity-center. After the real build, replace rows with exports from
IAM Identity Center (see docs/build-checklist.md) and re-run or edit the workbook.

Usage: python3 evidence/build_access_review.py
"""
from datetime import date
from pathlib import Path

from openpyxl import Workbook
from openpyxl.formatting.rule import CellIsRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

OUT = Path(__file__).resolve().parent / "access-review-Q4-2026.xlsx"
BANNER = "EXAMPLE DATA - fictional users, IDs and tickets for a portfolio lab. Not a real organization."
ACCOUNT = "111111111111 (example)"

HDR_FILL = PatternFill("solid", fgColor="1F3864")
HDR_FONT = Font(bold=True, color="FFFFFF")
BANNER_FILL = PatternFill("solid", fgColor="FFF2CC")
BANNER_FONT = Font(bold=True, color="9C5700")
THIN = Side(style="thin", color="BFBFBF")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
WRAP = Alignment(wrap_text=True, vertical="top")


def sheet(wb, title, headers, rows, widths=None, first=False):
    ws = wb.active if first else wb.create_sheet()
    ws.title = title
    ws["A1"] = BANNER
    ws["A1"].font = BANNER_FONT
    ws["A1"].fill = BANNER_FILL
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=max(len(headers), 1))
    for c, h in enumerate(headers, 1):
        cell = ws.cell(row=3, column=c, value=h)
        cell.fill, cell.font, cell.border, cell.alignment = HDR_FILL, HDR_FONT, BORDER, WRAP
    for r, row in enumerate(rows, 4):
        for c, v in enumerate(row, 1):
            cell = ws.cell(row=r, column=c, value=v)
            cell.border, cell.alignment = BORDER, WRAP
            if isinstance(v, date):
                cell.number_format = "yyyy-mm-dd"
    for i, w in enumerate(widths or [18] * len(headers), 1):
        ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = "A4"
    if headers:
        ws.auto_filter.ref = f"A3:{get_column_letter(len(headers))}{max(3 + len(rows), 4)}"
    return ws


def dropdown(ws, col_letter, options, first_row=4, last_row=200):
    dv = DataValidation(type="list", formula1='"' + ",".join(options) + '"', allow_blank=True,
                        showErrorMessage=True, errorTitle="Invalid value",
                        error="Choose a value from the list: " + ", ".join(options))
    ws.add_data_validation(dv)
    dv.add(f"{col_letter}{first_row}:{col_letter}{last_row}")


wb = Workbook()

# ---------- About ----------
about = wb.active
about.title = "About"
lines = [
    ("Quarterly User Access Review - Q4 2026 (AWS IAM Identity Center lab)", Font(bold=True, size=14)),
    (BANNER, BANNER_FONT),
    ("", None),
    ("Scope: IAM Identity Center users, groups, permission sets and account assignments for lab account " + ACCOUNT + ".", None),
    ("Review period: 2026-07-01 to 2026-09-30. Review performed: 2026-10-12 to 2026-10-16.", None),
    ("Controls supported: NIST 800-53 AC-2 (account management), AC-2(3) (disable inactive accounts), AC-6 (least privilege), AC-5 (separation of duties), IA-2(1) (MFA).", None),
    ("Inactivity rule used: no sign-in for 90+ days = stale; disable, then remove after manager confirmation.", None),
    ("", None),
    ("Sheets:", Font(bold=True)),
    ("  Users / Groups / PermissionSets / Assignments - inventory exported from Identity Center (here: matches Terraform defaults).", None),
    ("  Q4-Review - one row per user entitlement; reviewer records Keep / Modify / Revoke with justification and ticket #.", None),
    ("  Findings - issues found during the review. Remediation - tracking to closure with evidence.", None),
    ("  Sign-off - reviewer and control owner attestation.", None),
    ("", None),
    ("Regenerate: python3 evidence/build_access_review.py", None),
]
for i, (text, font) in enumerate(lines, 1):
    c = about.cell(row=i, column=1, value=text)
    if font:
        c.font = font
    if text == BANNER:
        c.fill = BANNER_FILL
about.column_dimensions["A"].width = 140

# ---------- Inventory ----------
users = [
    # username, display, title, groups, status, created, last sign-in, MFA, manager, source
    ("jdoe.helpdesk", "Jane Doe", "Service Desk Analyst II", "HelpDesk", "Enabled", date(2026, 6, 2), date(2026, 10, 9), "Yes (authenticator app)", "Pat Rivera", "REQ-10102 (joiner)"),
    ("tnguyen.helpdesk", "Tom Nguyen", "Service Desk Analyst I", "HelpDesk", "Enabled", date(2026, 3, 16), date(2026, 6, 24), "Yes (authenticator app)", "Pat Rivera", "REQ-09817 (joiner)"),
    ("asmith.admin", "Alex Smith", "Cloud Administrator", "CloudAdmins", "Enabled", date(2026, 1, 12), date(2026, 10, 14), "Yes (security key)", "Dana Okafor", "REQ-09450 (joiner)"),
    ("mlee.auditor", "Morgan Lee", "IT Auditor", "ReadOnlyAuditors", "Enabled", date(2026, 4, 6), date(2026, 10, 13), "Yes (authenticator app)", "Dana Okafor", "REQ-09902 (joiner)"),
    ("rpatel.dev", "Ravi Patel", "Software Developer", "Developers", "Enabled", date(2026, 5, 4), date(2026, 10, 1), "Yes (authenticator app)", "Chris Jordan", "REQ-10011 (joiner)"),
    ("kbrown.dev", "Kim Brown", "Software Developer", "Developers; CloudAdmins*", "Enabled", date(2026, 5, 4), date(2026, 10, 15), "Yes (authenticator app)", "Chris Jordan", "REQ-10012 (joiner); *CloudAdmins added in console 2026-08-21, no ticket"),
]
sheet(wb, "Users",
      ["Username", "Display name", "Title", "Group(s)", "Status", "Created", "Last sign-in", "MFA registered", "Manager", "Source ticket / notes"],
      [(u[0], u[1], u[2], u[3], u[4], u[5], u[6], u[7], u[8], u[9]) for u in users],
      [20, 16, 24, 24, 10, 12, 13, 24, 14, 48])

sheet(wb, "Groups",
      ["Group", "Description", "Permission set", "Target account", "Members", "Group owner"],
      [
          ("HelpDesk", "Tier 1/2 service desk; view-only troubleshooting", "HelpDesk (custom)", ACCOUNT, 2, "Pat Rivera"),
          ("CloudAdmins", "Cloud administrators", "AdministratorAccess", ACCOUNT, "2 (1 expected)", "Dana Okafor"),
          ("ReadOnlyAuditors", "Internal audit / GRC", "ViewOnlyAccess", ACCOUNT, 1, "Dana Okafor"),
          ("Developers", "Application developers", "ReadOnlyAccess", ACCOUNT, 2, "Chris Jordan"),
      ],
      [18, 44, 22, 24, 14, 16])

sheet(wb, "PermissionSets",
      ["Permission set", "Policy type", "Policies", "Session duration", "Assigned to", "Risk tier", "Notes"],
      [
          ("AdministratorAccess", "AWS managed", "AdministratorAccess", "1 hour", "CloudAdmins", "High", "Short session limits privileged exposure"),
          ("HelpDesk", "Custom inline", "View EC2/ELB/ASG/CloudWatch, view IAM; explicit Deny on terminate/stop/delete, IAM writes, SSO/Identity Store writes, Organizations", "4 hours", "HelpDesk", "Low", "Least-privilege custom set"),
          ("ReadOnlyAccess", "AWS managed", "ReadOnlyAccess", "4 hours", "Developers", "Medium", "Can read data (e.g. S3 objects)"),
          ("ViewOnlyAccess", "AWS managed", "job-function/ViewOnlyAccess", "2 hours", "ReadOnlyAuditors", "Low", "Metadata only; suits audit"),
      ],
      [22, 14, 60, 16, 18, 10, 36])

entitlements = [
    ("jdoe.helpdesk", "HelpDesk", "HelpDesk"),
    ("tnguyen.helpdesk", "HelpDesk", "HelpDesk"),
    ("asmith.admin", "CloudAdmins", "AdministratorAccess"),
    ("mlee.auditor", "ReadOnlyAuditors", "ViewOnlyAccess"),
    ("rpatel.dev", "Developers", "ReadOnlyAccess"),
    ("kbrown.dev", "Developers", "ReadOnlyAccess"),
    ("kbrown.dev", "CloudAdmins", "AdministratorAccess"),
]
sheet(wb, "Assignments",
      ["Username", "Group", "Permission set", "Target account", "Assignment type", "In Terraform?"],
      [(u, g, p, ACCOUNT, "Via group", "No - console drift" if (u, g) == ("kbrown.dev", "CloudAdmins") else "Yes")
       for u, g, p in entitlements],
      [20, 18, 22, 24, 16, 20])

# ---------- Q4 Review ----------
last = {u[0]: u[6] for u in users}
mfa = {u[0]: u[7] for u in users}
review_rows = [
    ("AR-Q4-001", "jdoe.helpdesk", "HelpDesk", "HelpDesk", last["jdoe.helpdesk"], mfa["jdoe.helpdesk"], "Pat Rivera", "Keep", "Active analyst; access matches role", date(2026, 10, 12), "REQ-10560", "Complete"),
    ("AR-Q4-002", "tnguyen.helpdesk", "HelpDesk", "HelpDesk", last["tnguyen.helpdesk"], mfa["tnguyen.helpdesk"], "Pat Rivera", "Revoke", "No sign-in for 116 days (on extended leave). Disable now; re-enable via joiner ticket on return", date(2026, 10, 12), "REQ-10561", "Remediating"),
    ("AR-Q4-003", "asmith.admin", "CloudAdmins", "AdministratorAccess", last["asmith.admin"], mfa["asmith.admin"], "Dana Okafor", "Keep", "Primary cloud admin; uses security key MFA", date(2026, 10, 13), "REQ-10562", "Complete"),
    ("AR-Q4-004", "mlee.auditor", "ReadOnlyAuditors", "ViewOnlyAccess", last["mlee.auditor"], mfa["mlee.auditor"], "Dana Okafor", "Keep", "Audit role; view-only appropriate", date(2026, 10, 13), "REQ-10563", "Complete"),
    ("AR-Q4-005", "rpatel.dev", "Developers", "ReadOnlyAccess", last["rpatel.dev"], mfa["rpatel.dev"], "Chris Jordan", "Keep", "Active developer", date(2026, 10, 14), "REQ-10564", "Complete"),
    ("AR-Q4-006", "kbrown.dev", "Developers", "ReadOnlyAccess", last["kbrown.dev"], mfa["kbrown.dev"], "Chris Jordan", "Keep", "Active developer", date(2026, 10, 14), "REQ-10565", "Complete"),
    ("AR-Q4-007", "kbrown.dev", "CloudAdmins", "AdministratorAccess", last["kbrown.dev"], mfa["kbrown.dev"], "Dana Okafor", "Revoke", "Added in console during an outage with no ticket or approval; developer role does not need admin", date(2026, 10, 14), "REQ-10566", "Remediating"),
]
rv = sheet(wb, "Q4-Review",
           ["Review ID", "Username", "Group", "Permission set", "Last sign-in", "MFA", "Reviewer", "Decision", "Justification", "Review date", "Ticket #", "Status"],
           review_rows, [11, 18, 17, 20, 12, 22, 14, 11, 52, 12, 11, 13])
dropdown(rv, "H", ["Keep", "Modify", "Revoke"])
dropdown(rv, "L", ["Not started", "Complete", "Remediating", "Closed"])
red = PatternFill("solid", fgColor="F8CBAD")
amber = PatternFill("solid", fgColor="FFE699")
rv.conditional_formatting.add("H4:H200", CellIsRule(operator="equal", formula=['"Revoke"'], fill=red))
rv.conditional_formatting.add("H4:H200", CellIsRule(operator="equal", formula=['"Modify"'], fill=amber))

# ---------- Findings ----------
fd = sheet(wb, "Findings",
           ["Finding ID", "Severity", "Title", "Affected user", "Description", "Control", "Root cause", "Recommended action", "Owner", "Due date", "Ticket #"],
           [
               ("F-Q4-01", "High", "Over-privileged user (unapproved admin)", "kbrown.dev",
                "Developer was added to CloudAdmins (AdministratorAccess) in the Identity Center console on 2026-08-21. No ticket or approval. Not in Terraform.",
                "AC-6, AC-2, AC-5", "Emergency change made outside change process; no drift detection",
                "Remove from CloudAdmins; run scripts/check_membership_drift.py to confirm no drift; schedule it weekly; use a documented break-glass process for outages",
                "Dana Okafor", date(2026, 10, 16), "REQ-10566"),
               ("F-Q4-02", "Medium", "Stale account (inactive > 90 days)", "tnguyen.helpdesk",
                "Last sign-in 2026-06-24 (116 days before review). User on extended leave; account still enabled with HelpDesk access.",
                "AC-2(3)", "Leave of absence not sent to service desk as a mover/leaver event",
                "Disable user in Identity Center; add HR leave events to the JML runbook triggers",
                "Pat Rivera", date(2026, 10, 19), "REQ-10561"),
               ("F-Q4-03", "Low", "Review evidence gap", "(process)",
                "Last-sign-in data had to be pulled from CloudTrail manually; no saved query.",
                "AC-2(4), AU-6", "No standard evidence export", "Save a CloudTrail Lake / Athena or CLI query in the build checklist for the next review",
                "Lamont (lab owner)", date(2026, 12, 31), "REQ-10567"),
           ],
           [10, 10, 30, 16, 50, 14, 34, 50, 16, 12, 11])
dropdown(fd, "B", ["Critical", "High", "Medium", "Low"])

# ---------- Remediation ----------
rm = sheet(wb, "Remediation",
           ["Finding ID", "Action", "Owner", "Status", "Opened", "Due", "Closed", "Evidence reference", "Verified by", "Verified date"],
           [
               ("F-Q4-01", "Remove kbrown.dev from CloudAdmins group", "Dana Okafor", "Done", date(2026, 10, 14), date(2026, 10, 16), date(2026, 10, 15), "screenshots/13-kbrown-groups-after.png; drift script reports no drift", "Morgan Lee", date(2026, 10, 15)),
               ("F-Q4-01", "Schedule weekly membership drift check (scripts/check_membership_drift.py)", "Lamont (lab owner)", "In Progress", date(2026, 10, 15), date(2026, 11, 15), None, "", "", None),
               ("F-Q4-02", "Disable tnguyen.helpdesk in Identity Center", "Pat Rivera", "Done", date(2026, 10, 12), date(2026, 10, 19), date(2026, 10, 13), "screenshots/12-tnguyen-disabled.png", "Morgan Lee", date(2026, 10, 13)),
               ("F-Q4-02", "Add leave-of-absence trigger to JML runbook", "Lamont (lab owner)", "Done", date(2026, 10, 13), date(2026, 10, 31), date(2026, 10, 16), "docs/jml-runbook.md section 2", "Pat Rivera", date(2026, 10, 16)),
               ("F-Q4-03", "Document last-sign-in evidence query", "Lamont (lab owner)", "Open", date(2026, 10, 16), date(2026, 12, 31), None, "", "", None),
           ],
           [10, 46, 18, 13, 12, 12, 12, 52, 14, 13])
dropdown(rm, "D", ["Open", "In Progress", "Done", "Risk Accepted"])
green = PatternFill("solid", fgColor="C6EFCE")
rm.conditional_formatting.add("D4:D200", CellIsRule(operator="equal", formula=['"Done"'], fill=green))
rm.conditional_formatting.add("D4:D200", CellIsRule(operator="equal", formula=['"Open"'], fill=red))

# ---------- Sign-off ----------
so = sheet(wb, "Sign-off",
           ["Role", "Name", "Attestation", "Signature", "Date"],
           [
               ("Reviewer - HelpDesk group", "Pat Rivera", "I reviewed all HelpDesk entitlements and recorded a decision for each.", "/s/ P. Rivera", date(2026, 10, 12)),
               ("Reviewer - Developers group", "Chris Jordan", "I reviewed all Developers entitlements and recorded a decision for each.", "/s/ C. Jordan", date(2026, 10, 14)),
               ("Reviewer - CloudAdmins / Auditors", "Dana Okafor", "I reviewed all privileged and audit entitlements and recorded a decision for each.", "/s/ D. Okafor", date(2026, 10, 14)),
               ("Independent verifier", "Morgan Lee", "I verified Revoke decisions were carried out (see Remediation).", "/s/ M. Lee", date(2026, 10, 16)),
               ("Control owner (AC-2)", "Dana Okafor", "Q4 2026 access review complete. Open items tracked in Remediation.", "/s/ D. Okafor", date(2026, 10, 16)),
               ("Prepared by", "Lamont (lab owner)", "Workbook compiled from Identity Center export and CloudTrail sign-in events.", "", None),
           ],
           [32, 20, 70, 16, 12])

wb.save(OUT)
print(f"wrote {OUT}")
