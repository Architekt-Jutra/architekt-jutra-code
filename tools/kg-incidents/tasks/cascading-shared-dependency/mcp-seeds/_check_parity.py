"""One-off parity check: Cypher seed vs JSON seeds.

Ensures service/datastore/dependency/team/person names referenced in
static-nodes.cypher also appear in catalog.json and changes.json — prevents drift.

Run manually: python3 _check_parity.py
"""

import json
import re
from pathlib import Path

HERE = Path(__file__).parent
TASK = HERE.parent


def cypher_services():
    text = (TASK / "kg-seed/static-nodes.cypher").read_text()
    return set(re.findall(r'MERGE \(s:Service \{name: "([^"]+)"\}\)', text))


def cypher_datastores():
    text = (TASK / "kg-seed/static-nodes.cypher").read_text()
    return set(re.findall(r'MERGE \(d:Datastore \{name: "([^"]+)"\}\)', text))


def cypher_dependencies():
    text = (TASK / "kg-seed/static-nodes.cypher").read_text()
    return set(re.findall(r'MERGE \(d:Dependency \{name: "([^"]+)"\}\)', text))


def cypher_revisions():
    text = (TASK / "kg-seed/static-nodes.cypher").read_text()
    return set(re.findall(r'MERGE \(r:Revision \{id: "([^"]+)"\}\)', text))


def check(a: set, b: set, name: str) -> bool:
    diff = a ^ b
    if diff:
        print(f"  [FAIL] {name} diff: {diff}")
        return False
    print(f"  [OK] {name} ({len(a)} entries)")
    return True


def main():
    catalog = json.load((TASK / "mcp-seeds/catalog.json").open())
    changes = json.load((TASK / "mcp-seeds/changes.json").open())

    c_svc = {s["name"] for s in catalog["services"]}
    c_ds = {d["name"] for d in catalog["datastores"]}
    c_dep = {d["name"] for d in catalog["dependencies"]}
    ch_rev = {r["id"] for r in changes["revisions"]}

    ok = all([
        check(cypher_services(), c_svc, "services (Cypher vs catalog.json)"),
        check(cypher_datastores(), c_ds, "datastores (Cypher vs catalog.json)"),
        check(cypher_dependencies(), c_dep, "dependencies (Cypher vs catalog.json)"),
        check(cypher_revisions(), ch_rev, "revisions (Cypher vs changes.json)"),
    ])
    if not ok:
        exit(1)
    print("parity ok")


if __name__ == "__main__":
    main()
