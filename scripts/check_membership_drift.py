#!/usr/bin/env python3
"""Compare live Identity Center group memberships with what Terraform defines.

Terraform only tracks memberships it created, so a user added to a group in the
console does not show up in `terraform plan`. This script catches that drift.

Usage (from repo root, with an SSO profile that can read Identity Center):
    export AWS_PROFILE=b3-lab
    python3 scripts/check_membership_drift.py
Exit code 0 = no drift, 1 = drift found.
"""
import json
import subprocess
import sys
from pathlib import Path

TF_DIR = Path(__file__).resolve().parent.parent / "terraform" / "02-identity-center"


def run(cmd, cwd=None):
    return json.loads(subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True).stdout)


def main():
    out = run(["terraform", "output", "-json"], cwd=TF_DIR)
    store = out["identity_store_id"]["value"]
    groups = out["group_ids"]["value"]  # name -> id
    expected = out["expected_memberships"]["value"]  # user -> [groups]
    users = {u["UserId"]: u["UserName"] for u in run(
        ["aws", "identitystore", "list-users", "--identity-store-id", store, "--output", "json"])["Users"]}

    actual = {}
    for gname, gid in groups.items():
        resp = run(["aws", "identitystore", "list-group-memberships", "--identity-store-id", store,
                    "--group-id", gid, "--output", "json"])
        for m in resp["GroupMemberships"]:
            uname = users.get(m["MemberId"]["UserId"], m["MemberId"]["UserId"])
            actual.setdefault(uname, []).append(gname)

    drift = False
    for uname in sorted(set(actual) | set(expected)):
        extra = sorted(set(actual.get(uname, [])) - set(expected.get(uname, [])))
        missing = sorted(set(expected.get(uname, [])) - set(actual.get(uname, [])))
        if extra:
            drift = True
            print(f"DRIFT  {uname}: in {extra} but not in Terraform (unapproved?)")
        if missing:
            drift = True
            print(f"DRIFT  {uname}: Terraform expects {missing} but membership is missing")
    print("Result:", "DRIFT FOUND" if drift else "no drift")
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
